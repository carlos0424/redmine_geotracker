# app/controllers/geotracker_api_controller.rb

class GeotrackerApiController < ApplicationController
    accept_api_auth :index, :show, :create, :update, :delete
    
    before_action :require_api_key
    before_action :find_project, except: [:global_stats]
    before_action :find_location, only: [:show, :update, :delete]
    
    def index
      @locations = @project.geotracker_locations
      
      # Aplicar filtros
      @locations = apply_filters(@locations)
      
      # Paginación
      if params[:limit].present?
        @locations = @locations.limit(params[:limit].to_i)
      end
      
      if params[:offset].present?
        @locations = @locations.offset(params[:offset].to_i)
      end
      
      respond_to do |format|
        format.json { render_json_api(@locations) }
        format.geojson { render_geojson(@locations) }
      end
    end
    
    def show
      respond_to do |format|
        format.json { render_json_api(@location) }
        format.geojson { render_geojson(@location) }
      end
    end
    
    def create
      @location = GeotrackerLocation.new(location_params)
      @location.project = @project
      @location.user = User.current
      
      if @location.save
        respond_to do |format|
          format.json { render_json_api(@location, status: :created) }
          format.geojson { render_geojson(@location, status: :created) }
        end
      else
        respond_to do |format|
          format.json { render_validation_errors(@location) }
          format.geojson { render_validation_errors(@location) }
        end
      end
    end
    
    def update
      if @location.update(location_params)
        respond_to do |format|
          format.json { render_json_api(@location) }
          format.geojson { render_geojson(@location) }
        end
      else
        respond_to do |format|
          format.json { render_validation_errors(@location) }
          format.geojson { render_validation_errors(@location) }
        end
      end
    end
    
    def delete
      if @location.destroy
        head :no_content
      else
        respond_to do |format|
          format.json { render_validation_errors(@location) }
          format.geojson { render_validation_errors(@location) }
        end
      end
    end
    
    def batch_create
      @locations = []
      success = true
      
      Location.transaction do
        params[:locations].each do |location_params|
          location = GeotrackerLocation.new(location_params.permit!)
          location.project = @project
          location.user = User.current
          
          unless location.save
            success = false
            raise ActiveRecord::Rollback
          end
          
          @locations << location
        end
      end
      
      if success
        respond_to do |format|
          format.json { render_json_api(@locations, status: :created) }
          format.geojson { render_geojson(@locations, status: :created) }
        end
      else
        respond_to do |format|
          format.json { render_validation_errors(@locations.select { |l| l.errors.any? }) }
          format.geojson { render_validation_errors(@locations.select { |l| l.errors.any? }) }
        end
      end
    end
    
    def global_stats
      stats = {
        total_locations: GeotrackerLocation.count,
        total_projects: Project.with_module(:geotracker).count,
        total_users: User.active.joins(:geotracker_locations).distinct.count,
        recent_locations: GeotrackerLocation.where('created_at > ?', 24.hours.ago).count
      }
      
      respond_to do |format|
        format.json { render json: stats }
      end
    end
    
    private
    
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
    
    def find_location
      @location = @project.geotracker_locations.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
    
    def location_params
      params.require(:location).permit(
        :latitude,
        :longitude,
        :accuracy,
        :altitude,
        :speed,
        :heading,
        :activity_type,
        :battery_level,
        :issue_id,
        :notes,
        metadata: {}
      )
    end
    
    def apply_filters(scope)
      if params[:user_id].present?
        scope = scope.where(user_id: params[:user_id])
      end
      
      if params[:issue_id].present?
        scope = scope.where(issue_id: params[:issue_id])
      end
      
      if params[:start_date].present?
        scope = scope.where('created_at >= ?', params[:start_date])
      end
      
      if params[:end_date].present?
        scope = scope.where('created_at <= ?', params[:end_date])
      end
      
      if params[:within_bounds].present?
        bounds = params[:within_bounds].split(',').map(&:to_f)
        scope = scope.within_bounds(*bounds)
      end
      
      scope
    end
    
    def render_json_api(data, options = {})
      options[:status] ||= :ok
      
      if data.is_a?(Array)
        render json: {
          total_count: data.size,
          locations: data.map { |location| location_to_json(location) }
        }, status: options[:status]
      else
        render json: location_to_json(data), status: options[:status]
      end
    end
    
    def render_geojson(data, options = {})
      options[:status] ||= :ok
      
      feature_collection = {
        type: "FeatureCollection",
        features: data.is_a?(Array) ? data.map { |l| location_to_feature(l) } : [location_to_feature(data)]
      }
      
      render json: feature_collection, status: options[:status]
    end
    
    def location_to_json(location)
      {
        id: location.id,
        type: 'location',
        attributes: {
          latitude: location.coordinates.y,
          longitude: location.coordinates.x,
          accuracy: location.accuracy,
          altitude: location.altitude,
          speed: location.speed,
          heading: location.heading,
          activity_type: location.activity_type,
          battery_level: location.battery_level,
          created_at: location.created_at,
          updated_at: location.updated_at
        },
        relationships: {
          project: {
            id: location.project_id,
            name: location.project.name
          },
          user: {
            id: location.user_id,
            name: location.user.name
          },
          issue: location.issue_id ? {
            id: location.issue_id,
            subject: location.issue.subject
          } : nil
        }
      }
    end
    
    def location_to_feature(location)
      {
        type: "Feature",
        geometry: {
          type: "Point",
          coordinates: [location.coordinates.x, location.coordinates.y]
        },
        properties: location_to_json(location)
      }
    end
    
    def render_validation_errors(data)
      errors = data.is_a?(Array) ? data.map(&:errors) : data.errors
      render json: { errors: errors }, status: :unprocessable_entity
    end
    
    def require_api_key
      unless User.current.api_token?
        render json: { error: 'API key is required' }, status: :unauthorized
      end
    end
  end
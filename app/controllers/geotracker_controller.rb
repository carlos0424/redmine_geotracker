# app/controllers/geotracker_locations_controller.rb

class GeotrackerLocationsController < ApplicationController
    # Aseguramos que el usuario esté autenticado
    before_action :require_login
    
    # Cargamos el proyecto si se especifica
    before_action :find_project, only: [:index, :create]
    
    # Verificamos permisos
    before_action :authorize_global
    
    # Lista de ubicaciones con filtros
    def index
      @locations = GeotrackerLocation.recent
      
      # Aplicamos filtros si existen
      @locations = @locations.by_project(@project.id) if @project
      @locations = @locations.by_user(params[:user_id]) if params[:user_id]
      @locations = @locations.by_issue(params[:issue_id]) if params[:issue_id]
      
      # Paginación
      @locations = @locations.page(params[:page]).per_page(20)
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @locations }
        format.geojson { render json: locations_to_geojson(@locations) }
      end
    end
    
    # Crear nuevo registro de ubicación
    def create
      @location = GeotrackerLocation.new(location_params)
      @location.user = User.current
      @location.project = @project if @project
      
      if @location.save
        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_location_created)
            redirect_to geotracker_locations_path
          }
          format.json { render json: @location, status: :created }
        end
      else
        respond_to do |format|
          format.html {
            flash[:error] = l(:error_location_create)
            render :new
          }
          format.json { render json: @location.errors, status: :unprocessable_entity }
        end
      end
    end
    
    private
    
    def find_project
      @project = Project.find(params[:project_id]) if params[:project_id]
    rescue ActiveRecord::RecordNotFound
      render_404
    end
    
    # Parámetros permitidos
    def location_params
      params.require(:geotracker_location).permit(
        :issue_id,
        :coordinates,
        :accuracy,
        :altitude,
        :speed,
        :device_id,
        :connection_type,
        :battery_level,
        :additional_data,
        :notes,
        :is_manual
      )
    end
    
    # Convierte ubicaciones a formato GeoJSON
    def locations_to_geojson(locations)
      {
        type: "FeatureCollection",
        features: locations.map do |location|
          {
            type: "Feature",
            geometry: {
              type: "Point",
              coordinates: [
                location.coordinates.x, # longitud
                location.coordinates.y  # latitud
              ]
            },
            properties: {
              id: location.id,
              issue_id: location.issue_id,
              created_at: location.created_at,
              user: location.user.name,
              # Más propiedades según necesites
            }
          }
        end
      }
    end
  end
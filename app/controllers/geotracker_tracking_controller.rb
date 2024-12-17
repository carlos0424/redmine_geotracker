# app/controllers/geotracker_tracking_controller.rb

class GeotrackerTrackingController < ApplicationController
    before_action :require_login
    before_action :find_project
    before_action :authorize
    
    # Endpoint para recibir actualizaciones de ubicación
    def update_location
      @location = GeotrackerLocation.new(location_params)
      @location.user = User.current
      @location.project = @project
      
      if @location.save
        # Transmitir la ubicación a otros usuarios conectados
        broadcast_location(@location)
        render json: { success: true, location: location_to_json(@location) }
      else
        render json: { success: false, errors: @location.errors.full_messages }, 
               status: :unprocessable_entity
      end
    end
    
    # Endpoint para exportar datos
    def export
      @locations = @project.geotracker_locations
      
      # Aplicar filtros
      @locations = @locations.by_user(params[:user_id]) if params[:user_id].present?
      @locations = @locations.by_date_range(params[:start_date], params[:end_date]) if params[:start_date].present?
      
      respond_to do |format|
        format.csv { send_data export_to_csv(@locations), filename: "locations-#{Date.today}.csv" }
        format.gpx { send_data export_to_gpx(@locations), filename: "locations-#{Date.today}.gpx" }
        format.json { send_data export_to_json(@locations), filename: "locations-#{Date.today}.json" }
        format.kml { send_data export_to_kml(@locations), filename: "locations-#{Date.today}.kml" }
      end
    end
    
    # Endpoint para obtener el estado actual de seguimiento
    def status
      @active_users = GeotrackerLocation.active_users(@project)
      render json: {
        active_users: @active_users.map { |u| { id: u.id, name: u.name } },
        last_update: GeotrackerLocation.last_update_for_project(@project)
      }
    end
  
    private
    
    def location_params
      params.require(:location).permit(
        :latitude, :longitude, :accuracy, :altitude,
        :speed, :heading, :activity_type, :battery_level,
        :issue_id, :notes, metadata: {}
      )
    end
    
    def broadcast_location(location)
      ActionCable.server.broadcast(
        "geotracker_#{@project.id}",
        location: location_to_json(location)
      )
    end
    
    def location_to_json(location)
      {
        id: location.id,
        user: { id: location.user_id, name: location.user.name },
        coordinates: {
          lat: location.coordinates.y,
          lng: location.coordinates.x
        },
        accuracy: location.accuracy,
        created_at: location.created_at,
        issue_id: location.issue_id,
        metadata: location.metadata
      }
    end
    
    def export_to_csv(locations)
      CSV.generate do |csv|
        # Encabezados
        csv << ["ID", "User", "Latitude", "Longitude", "Accuracy", "Created At", "Issue", "Notes"]
        
        # Datos
        locations.each do |loc|
          csv << [
            loc.id,
            loc.user.name,
            loc.coordinates.y,
            loc.coordinates.x,
            loc.accuracy,
            loc.created_at,
            loc.issue_id,
            loc.notes
          ]
        end
      end
    end
    
    def export_to_gpx(locations)
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.gpx(version: "1.1", creator: "Redmine GeoTracker") {
          xml.metadata {
            xml.name "Project #{@project.name} Locations"
            xml.time Time.current.iso8601
          }
          
          locations.each do |loc|
            xml.wpt(lat: loc.coordinates.y, lon: loc.coordinates.x) {
              xml.time loc.created_at.iso8601
              xml.name "Location #{loc.id}"
              xml.desc "User: #{loc.user.name}"
              xml.extensions {
                xml.accuracy loc.accuracy if loc.accuracy
                xml.issue_id loc.issue_id if loc.issue_id
              }
            }
          end
        }
      end
      builder.to_xml
    end
    
    def export_to_kml(locations)
      builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
        xml.kml(xmlns: "http://www.opengis.net/kml/2.2") {
          xml.Document {
            xml.name "Project #{@project.name} Locations"
            
            locations.each do |loc|
              xml.Placemark {
                xml.name "Location #{loc.id}"
                xml.description "User: #{loc.user.name}\nTime: #{loc.created_at}"
                xml.Point {
                  xml.coordinates "#{loc.coordinates.x},#{loc.coordinates.y}"
                }
              }
            end
          }
        }
      end
      builder.to_xml
    end
  end
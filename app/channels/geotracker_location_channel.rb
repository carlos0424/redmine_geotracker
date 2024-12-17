# app/channels/geotracker_location_channel.rb

class GeotrackerLocationChannel < ApplicationCable::Channel
    def subscribed
      if project_id = params[:project_id]
        project = Project.find_by(id: project_id)
        if project && User.current.allowed_to?(:view_locations, project)
          stream_from "geotracker_#{project_id}"
        end
      end
    end
  
    def unsubscribed
      stop_all_streams
    end
  
    def update_status(data)
      return unless current_user
      
      GeotrackerLocation.create!(
        user: current_user,
        project_id: params[:project_id],
        coordinates: "POINT(#{data['lng']} #{data['lat']})",
        accuracy: data['accuracy'],
        metadata: {
          battery_level: data['batteryLevel'],
          connection_type: data['connectionType']
        }
      )
    end
  end
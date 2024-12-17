# app/helpers/geotracker_helper.rb

module GeotrackerHelper
    def format_coordinates(point)
      return unless point
      lat = point.y.round(6)
      lng = point.x.round(6)
      "#{lat}, #{lng}"
    end
  
    def map_data(locations)
      locations.map do |location|
        {
          id: location.id,
          lat: location.coordinates.y,
          lng: location.coordinates.x,
          title: location_title(location),
          popup: render(partial: 'location_popup', locals: { location: location })
        }
      end.to_json
    end
  
    def location_title(location)
      parts = []
      parts << location.user.name
      parts << "##{location.issue.id}" if location.issue
      parts << I18n.l(location.created_at, format: :short)
      parts.join(' - ')
    end
  
    def location_status_options
      GeotrackerLocation::STATUSES.map do |status|
        [l(:"location_status_#{status}"), status]
      end
    end
  end
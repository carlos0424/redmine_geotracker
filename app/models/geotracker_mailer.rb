# app/models/geotracker_mailer.rb

class GeotrackerMailer < Mailer
    def location_update_notification(user, location)
      @location = location
      @project = location.project
      @user = location.user
      @url = url_for(controller: 'geotracker_locations', 
                     action: 'show',
                     id: location.id,
                     project_id: @project.id)
  
      mail to: user.mail,
           subject: l(:mail_subject_location_update, 
                     project: @project.name,
                     user: @user.name)
    end
  
    def daily_location_summary(user, project, locations)
      @project = project
      @locations = locations
      @url = url_for(controller: 'geotracker_locations',
                     action: 'index',
                     project_id: @project.id)
  
      mail to: user.mail,
           subject: l(:mail_subject_daily_location_summary,
                     project: @project.name,
                     count: locations.count)
    end
  end
  
  # app/models/geotracker_notification.rb
  
  class GeotrackerNotification
    def self.notify_location_update(location)
      users_to_notify = location.project.users.select do |user|
        user.allowed_to?(:view_locations, location.project) &&
        user.notify_about?('location_updates')
      end
  
      users_to_notify.each do |user|
        GeotrackerMailer.location_update_notification(user, location).deliver_later
      end
    end
  
    def self.send_daily_summaries
      Project.active.each do |project|
        next unless project.module_enabled?('geotracker')
  
        yesterday = Time.current.yesterday.all_day
        locations = project.geotracker_locations.where(created_at: yesterday)
        
        next if locations.empty?
  
        users_to_notify = project.users.select do |user|
          user.allowed_to?(:view_locations, project) &&
          user.notify_about?('daily_summaries')
        end
  
        users_to_notify.each do |user|
          GeotrackerMailer.daily_location_summary(user, project, locations).deliver_later
        end
      end
    end
  end
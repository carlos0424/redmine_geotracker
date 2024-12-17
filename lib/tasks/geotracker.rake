# lib/tasks/geotracker.rake

namespace :redmine do
    namespace :geotracker do
      desc 'Limpiar ubicaciones antiguas según la política de retención'
      task cleanup_old_locations: :environment do
        retention_days = Setting.plugin_redmine_geotracker[:retention_period].to_i
        if retention_days > 0
          cutoff_date = retention_days.days.ago
          
          GeotrackerLocation.where('created_at < ?', cutoff_date).find_each do |location|
            location.archive!
          end
        end
      end
      
      desc 'Generar reportes diarios de ubicaciones'
      task generate_daily_reports: :environment do
        Project.active.each do |project|
          next unless project.module_enabled?(:geotracker)
          
          yesterday = Time.current.yesterday.all_day
          locations = project.geotracker_locations.where(created_at: yesterday)
          
          next if locations.empty?
          
          report = GeotrackerDailyReport.create!(
            project: project,
            date: yesterday.begin,
            location_count: locations.count,
            user_count: locations.select(:user_id).distinct.count,
            total_distance: calculate_total_distance(locations),
            stats: generate_location_stats(locations)
          )
          
          # Notificar a los usuarios configurados
          notify_daily_report(report)
        end
      end
      
      desc 'Optimizar datos geoespaciales'
      task optimize_spatial_data: :environment do
        ActiveRecord::Base.connection.execute(<<-SQL)
          VACUUM ANALYZE geotracker_locations;
          CLUSTER geotracker_locations USING index_geotracker_locations_on_coordinates;
        SQL
      end
      
      desc 'Sincronizar datos pendientes'
      task sync_pending_data: :environment do
        GeotrackerLocation.where(sync_status: 'pending').find_each do |location|
          location.try_sync!
        end
      end
      
      private
      
      def calculate_total_distance(locations)
        total = 0
        locations.order(:created_at).each_cons(2) do |loc1, loc2|
          total += calculate_distance(loc1, loc2)
        end
        total
      end
      
      def calculate_distance(loc1, loc2)
        # Fórmula Haversine para calcular distancia entre puntos
        ActiveRecord::Base.connection.execute(<<-SQL).first['distance']
          SELECT ST_Distance(
            '#{loc1.coordinates}'::geography,
            '#{loc2.coordinates}'::geography
          ) as distance;
        SQL
      end
      
      def generate_location_stats(locations)
        {
          by_hour: locations.group_by_hour(:created_at).count,
          by_user: locations.group(:user_id).count,
          by_accuracy: {
            high: locations.where('accuracy <= ?', 10).count,
            medium: locations.where('accuracy > ? AND accuracy <= ?', 10, 50).count,
            low: locations.where('accuracy > ?', 50).count
          }
        }
      end
      
      def notify_daily_report(report)
        users_to_notify = report.project.users.select do |user|
          user.allowed_to?(:view_locations, report.project) &&
          user.notify_about?('daily_reports')
        end
        
        users_to_notify.each do |user|
          GeotrackerMailer.daily_report_notification(user, report).deliver_later
        end
      end
    end
  end
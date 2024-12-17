# lib/geotracker/monitoring.rb

module Geotracker
    module Monitoring
      class << self
        def setup
          setup_logging
          setup_error_tracking
          setup_performance_monitoring
          setup_health_checks
        end
  
        private
  
        def setup_logging
          Geotracker.logger = Logger.new(Rails.root.join('log', 'geotracker.log'))
          
          Geotracker.logger.formatter = proc do |severity, datetime, progname, msg|
            {
              timestamp: datetime.iso8601,
              level: severity,
              program: progname,
              message: msg,
              environment: Rails.env
            }.to_json + "\n"
          end
        end
  
        def setup_error_tracking
          if defined?(Sentry)
            Sentry.init do |config|
              config.dsn = Setting.plugin_redmine_geotracker[:sentry_dsn]
              config.traces_sample_rate = 0.1
              config.traces_sampler = lambda do |sampling_context|
                transaction = sampling_context[:transaction_context]
                case transaction[:name]
                when /^\/api\//
                  0.5  # Sample 50% of API requests
                else
                  0.1  # Sample 10% of other requests
                end
              end
            end
          end
        end
  
        def setup_performance_monitoring
          ActiveSupport::Notifications.subscribe "process_action.action_controller" do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            
            if event.payload[:controller].start_with?('Geotracker')
              StatsD.timing(
                "geotracker.controller.#{event.payload[:action]}.duration",
                event.duration
              )
              
              StatsD.increment(
                "geotracker.controller.#{event.payload[:action]}.count"
              )
            end
          end
  
          # Monitor ubicaciones creadas
          ActiveSupport::Notifications.subscribe "geotracker.location.created" do |*args|
            StatsD.increment("geotracker.location.created")
          end
  
          # Monitor consultas espaciales
          ActiveSupport::Notifications.subscribe "geotracker.spatial_query" do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            StatsD.timing("geotracker.spatial_query.duration", event.duration)
          end
        end
  
        def setup_health_checks
          Geotracker::HealthCheck.checks do |checks|
            # Verificar conexión a la base de datos
            checks.add :database do
              GeotrackerLocation.connection.active?
            end
  
            # Verificar extensión PostGIS
            checks.add :postgis do
              result = ActiveRecord::Base.connection.execute("SELECT PostGIS_version()")
              result.any?
            end
  
            # Verificar espacio en disco
            checks.add :disk_space do
              storage_path = Rails.root.join('files', 'geotracker')
              free_space = Sys::Filesystem.stat(storage_path).bytes_free
              free_space > 1.gigabyte
            end
  
            # Verificar caché
            checks.add :cache do
              Rails.cache.write('health_check', 1)
              Rails.cache.read('health_check') == 1
            end
          end
        end
      end
    end
  
    class HealthCheck
      class << self
        def checks(&block)
          @checks ||= []
          yield self if block_given?
          @checks
        end
  
        def add(name, &block)
          @checks << { name: name, check: block }
        end
  
        def run
          results = {}
          @checks.each do |check|
            begin
              results[check[:name]] = {
                status: check[:check].call ? 'ok' : 'fail',
                timestamp: Time.current
              }
            rescue => e
              results[check[:name]] = {
                status: 'error',
                error: e.message,
                timestamp: Time.current
              }
            end
          end
          results
        end
      end
    end
  end
# lib/geotracker/debug.rb

module Geotracker
    module Debug
      class << self
        def setup
          setup_query_logging
          setup_performance_profiling
          setup_memory_profiling if Rails.env.development?
        end
  
        private
  
        def setup_query_logging
          ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            
            if event.payload[:sql].include?('postgis') || 
               event.payload[:sql].include?('geography')
              
              Geotracker.logger.debug({
                type: 'spatial_query',
                sql: event.payload[:sql],
                duration: event.duration,
                timestamp: Time.current
              }.to_json)
            end
          end
        end
  
        def setup_performance_profiling
          return unless Rails.env.development?
  
          require 'rack-mini-profiler'
          
          Rack::MiniProfiler.config.position = 'bottom-right'
          Rack::MiniProfiler.config.start_hidden = true
          
          # Agregar custom timers para consultas espaciales
          Rack::MiniProfiler.profile_singleton_method(
            GeotrackerLocation, :within_bounds
          ) { |a| "GeotrackerLocation.within_bounds" }
        end
  
        def setup_memory_profiling
          require 'memory_profiler'
  
          ActiveSupport::Notifications.subscribe('geotracker.memory_snapshot') do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            
            report = MemoryProfiler.report do
              yield if block_given?
            end
  
            report_path = Rails.root.join(
              'tmp',
              'memory_reports',
              "geotracker_#{Time.current.to_i}.txt"
            )
            
            FileUtils.mkdir_p(File.dirname(report_path))
            report.pretty_print(to_file: report_path)
          end
        end
      end
  
      module RequestDebugging
        extend ActiveSupport::Concern
  
        included do
          around_action :debug_request, if: -> { Rails.env.development? }
        end
  
        private
  
        def debug_request
          start_time = Time.current
          
          begin
            yield
          ensure
            duration = Time.current - start_time
            
            debug_info = {
              controller: params[:controller],
              action: params[:action],
              duration: duration,
              params: filtered_params,
              user: current_user&.login,
              memory: GetProcessMem.new.mb
            }
  
            Geotracker.logger.debug(debug_info.to_json)
          end
        end
  
        def filtered_params
          params.to_unsafe_h.except(
            'controller',
            'action',
            'password',
            'authenticity_token'
          )
        end
      end
    end
  end
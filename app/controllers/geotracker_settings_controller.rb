# app/controllers/geotracker_settings_controller.rb

class GeotrackerSettingsController < ApplicationController
    layout 'admin'
    
    before_action :require_admin
    before_action :find_project, only: [:project_settings]
    
    def show
      @settings = Setting.plugin_redmine_geotracker
    end
    
    def update
      settings = Setting.plugin_redmine_geotracker
      settings = {} unless settings.is_a?(Hash)
      
      # Actualizar configuraciones
      settings.merge!(params[:settings].permit(
        :default_update_interval,
        :minimum_accuracy,
        :enable_real_time_tracking,
        :track_battery_level,
        :track_network_status,
        :retention_period,
        :max_locations_per_user,
        notification_roles: [],
        tracking_schedule: [:start_time, :end_time, days: []]
      ).to_h)
      
      Setting.plugin_redmine_geotracker = settings
      
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: 'show'
    end
    
    def project_settings
      @settings = @project.geotracker_settings
      
      if request.post?
        @project.geotracker_settings = params[:settings]
        flash[:notice] = l(:notice_successful_update) if @project.save
      end
    end
    
    private
    
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
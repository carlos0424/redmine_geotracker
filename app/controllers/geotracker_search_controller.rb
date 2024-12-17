# app/controllers/geotracker_search_controller.rb

class GeotrackerSearchController < ApplicationController
    before_action :require_login
    before_action :find_project
    before_action :authorize
  
    def index
      @query = GeotrackerQuery.new(params[:query])
      @query.project = @project
      @query.user = User.current
  
      respond_to do |format|
        format.html {
          @limit = per_page_option
          @location_count = @query.location_count
          @location_pages = Paginator.new @location_count, @limit, params['page']
          @locations = @query.locations(offset: @location_pages.offset, limit: @limit)
          
          render 'geotracker_locations/index'
        }
        format.api  {
          @locations = @query.locations
        }
        format.atom {
          @locations = @query.locations(limit: Setting.feeds_limit.to_i)
        }
        format.csv  {
          send_data export_to_csv(@query.locations), filename: 'locations.csv'
        }
      end
    end
  
    def filter_options
      respond_to do |format|
        format.json {
          render json: {
            users: @project.users.map { |u| { id: u.id, name: u.name } },
            issues: @project.issues.open.map { |i| { id: i.id, subject: i.subject } },
            trackers: @project.trackers.map { |t| { id: t.id, name: t.name } },
            statuses: GeotrackerLocation::STATUSES
          }
        }
      end
    end
  
    private
  
    def find_project
      @project = Project.find(params[:project_id])
    rescue ActiveRecord::RecordNotFound
      render_404
    end
  end
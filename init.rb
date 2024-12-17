# init.rb
require 'redmine'

Rails.application.config.to_prepare do
  require_dependency 'application_helper'
  require_dependency 'queries_helper'
end

Redmine::Plugin.register :redmine_geotracker do
  name 'Redmine GeoTracker'
  author 'Carlos Arbelaez'
  description 'Plugin para tracking de ubicaciones en Redmine'
  version '0.0.1'

  project_module :geotracker do
    permission :view_locations, { geotracker_locations: [:index, :show] }
    permission :manage_locations, { geotracker_locations: [:new, :create, :edit, :update] }
  end
end
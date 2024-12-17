# test/system/geotracker_system_test.rb

require 'application_system_test_case'

class GeotrackerSystemTest < ApplicationSystemTestCase
  fixtures :projects, :users, :issues
  
  def setup
    @project = projects(:projects_001)
    @user = users(:users_001)
    log_user(@user.login, 'password')
  end
  
  test "visiting the index" do
    visit project_geotracker_locations_path(@project)
    assert_selector "h2", text: "Locations"
    assert_selector "#locations-map"
  end
  
  test "creating a new location" do
    visit new_project_geotracker_location_path(@project)
    
    fill_in "Latitude", with: 40.730610
    fill_in "Longitude", with: -73.935242
    fill_in "Accuracy", with: 10.0
    
    click_on "Create"
    
    assert_text "Location was successfully created"
  end
  
  test "updating a location" do
    location = GeotrackerLocation.create!(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    )
    
    visit edit_project_geotracker_location_path(@project, location)
    
    fill_in "Notes", with: "Updated location"
    click_on "Update"
    
    assert_text "Location was successfully updated"
  end
  
  test "real-time tracking interface" do
    visit project_geotracker_locations_path(@project)
    
    assert_selector "#tracking-controls"
    click_on "Start Tracking"
    
    # Esperar a que el tracking se inicie
    assert_selector "#tracking-status", text: "Tracking Active"
    
    click_on "Stop Tracking"
    assert_selector "#tracking-status", text: "Tracking Stopped"
  end
  
  test "filtering locations" do
    visit project_geotracker_locations_path(@project)
    
    fill_in "Start Date", with: Date.today.beginning_of_month.strftime("%Y-%m-%d")
    fill_in "End Date", with: Date.today.strftime("%Y-%m-%d")
    
    click_on "Apply Filter"
    
    assert_selector ".locations-list"
  end
  
  test "exporting data" do
    visit project_geotracker_locations_path(@project)
    
    click_on "Export"
    
    assert_selector ".export-options"
    click_on "Export as CSV"
    
    # Verificar que el archivo se descargó
    assert_downloaded_file
  end
end
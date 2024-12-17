# test/integration/geotracker_api_test.rb

require File.expand_path('../../test_helper', __FILE__)

class GeotrackerApiTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues
  
  def setup
    @project = projects(:projects_001)
    @user = users(:users_001)
    @api_key = @user.api_key
    
    # Crear algunas ubicaciones de prueba
    @location = GeotrackerLocation.create!(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    )
  end
  
  test "should get index with API key" do
    get "/api/v1/projects/#{@project.id}/geotracker_locations.json",
        headers: { 'X-Redmine-API-Key' => @api_key }
        
    assert_response :success
    json = JSON.parse(response.body)
    assert_not_nil json['locations']
  end
  
  test "should create location via API" do
    assert_difference 'GeotrackerLocation.count' do
      post "/api/v1/projects/#{@project.id}/geotracker_locations.json",
           params: {
             location: {
               latitude: 40.730610,
               longitude: -73.935242,
               accuracy: 10.0
             }
           },
           headers: { 'X-Redmine-API-Key' => @api_key }
    end
    
    assert_response :success
  end
  
  test "should batch create locations" do
    locations_data = [
      { latitude: 40.730610, longitude: -73.935242, accuracy: 10.0 },
      { latitude: 40.731610, longitude: -73.936242, accuracy: 15.0 }
    ]
    
    assert_difference 'GeotrackerLocation.count', 2 do
      post "/api/v1/projects/#{@project.id}/geotracker_locations/batch_create.json",
           params: { locations: locations_data },
           headers: { 'X-Redmine-API-Key' => @api_key }
    end
    
    assert_response :success
  end
  
  test "should return GeoJSON format" do
    get "/api/v1/projects/#{@project.id}/geotracker_locations.geojson",
        headers: { 'X-Redmine-API-Key' => @api_key }
        
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "FeatureCollection", json['type']
  end
  
  test "should handle validation errors" do
    post "/api/v1/projects/#{@project.id}/geotracker_locations.json",
         params: { location: { latitude: nil, longitude: nil } },
         headers: { 'X-Redmine-API-Key' => @api_key }
         
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_not_nil json['errors']
  end
end

# test/integration/geotracker_web_test.rb

class GeotrackerWebTest < ActionDispatch::IntegrationTest
  fixtures :projects, :users, :issues
  
  def setup
    @project = projects(:projects_001)
    @user = users(:users_001)
    log_user(@user.login, 'password')
  end
  
  test "should show locations page" do
    get "/projects/#{@project.identifier}/geotracker_locations"
    assert_response :success
  end
  
  test "should create new location" do
    assert_difference 'GeotrackerLocation.count' do
      post "/projects/#{@project.identifier}/geotracker_locations",
           params: {
             geotracker_location: {
               latitude: 40.730610,
               longitude: -73.935242,
               accuracy: 10.0
             }
           }
    end
    
    assert_redirected_to project_geotracker_locations_path(@project)
  end
  
  test "should show map view" do
    get "/projects/#{@project.identifier}/geotracker_locations/map"
    assert_response :success
    assert_select '#locations-map'
  end
  
  test "should export data" do
    get "/projects/#{@project.identifier}/geotracker_locations/export",
        params: { format: 'csv' }
    assert_response :success
    assert_equal 'text/csv', response.content_type
    
    get "/projects/#{@project.identifier}/geotracker_locations/export",
        params: { format: 'gpx' }
    assert_response :success
    assert_equal 'application/gpx+xml', response.content_type
  end
end
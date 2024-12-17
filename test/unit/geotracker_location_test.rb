# test/unit/geotracker_location_test.rb

require File.expand_path('../../test_helper', __FILE__)

class GeotrackerLocationTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues
  
  def setup
    @project = projects(:projects_001)
    @user = users(:users_001)
    @issue = issues(:issues_001)
    
    @valid_location = GeotrackerLocation.new(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    )
  end
  
  test "should not save location without project" do
    location = GeotrackerLocation.new
    assert_not location.save, "Saved location without project"
  end
  
  test "should not save location without coordinates" do
    location = GeotrackerLocation.new(project: @project, user: @user)
    assert_not location.save, "Saved location without coordinates"
  end
  
  test "should save valid location" do
    assert @valid_location.save, "Could not save valid location"
  end
  
  test "should validate coordinate format" do
    @valid_location.coordinates = 'INVALID'
    assert_not @valid_location.save, "Saved location with invalid coordinates"
  end
  
  test "should calculate distance between points" do
    location1 = GeotrackerLocation.create!(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    )
    
    location2 = GeotrackerLocation.create!(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.731610)', # 1 minute north
      accuracy: 10.0
    )
    
    distance = location1.distance_to(location2)
    assert distance > 0, "Distance calculation failed"
    assert_in_delta 111.0, distance/1000.0, 5.0, "Distance calculation inaccurate"
  end
  
  test "should handle metadata" do
    metadata = { 'battery_level' => 85, 'network' => '4G' }
    @valid_location.metadata = metadata
    assert @valid_location.save
    assert_equal metadata, @valid_location.reload.metadata
  end
  
  test "should validate accuracy range" do
    @valid_location.accuracy = -1
    assert_not @valid_location.valid?
    @valid_location.accuracy = 10000
    assert_not @valid_location.valid?
    @valid_location.accuracy = 10
    assert @valid_location.valid?
  end
end

# test/unit/geotracker_query_test.rb

class GeotrackerQueryTest < ActiveSupport::TestCase
  fixtures :projects, :users, :issues
  
  def setup
    @project = projects(:projects_001)
    @query = GeotrackerQuery.new(project: @project)
  end
  
  test "should filter by date range" do
    @query.add_filter('created_on', '><', ['2024-01-01', '2024-12-31'])
    assert @query.statement.include?('created_at BETWEEN')
  end
  
  test "should filter by user" do
    user = users(:users_001)
    @query.add_filter('user_id', '=', [user.id.to_s])
    assert @query.statement.include?('user_id')
  end
  
  test "should handle spatial filters" do
    @query.add_filter('within_radius', '=', ['40.730610', '-73.935242', '1000'])
    assert @query.statement.include?('ST_DWithin')
  end
end

# test/unit/geotracker_mailer_test.rb

class GeotrackerMailerTest < ActionMailer::TestCase
  fixtures :projects, :users
  
  def setup
    @project = projects(:projects_001)
    @user = users(:users_001)
    @location = GeotrackerLocation.create!(
      project: @project,
      user: @user,
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    )
  end
  
  test "location update notification" do
    email = GeotrackerMailer.location_update_notification(@user, @location).deliver
    assert !ActionMailer::Base.deliveries.empty?
    
    assert_equal [@user.mail], email.to
    assert_match /Location Update/, email.subject
    assert_match /#{@project.name}/, email.body.to_s
  end
  
  test "daily summary" do
    locations = [@location]
    email = GeotrackerMailer.daily_location_summary(@user, @project, locations).deliver
    
    assert !ActionMailer::Base.deliveries.empty?
    assert_equal [@user.mail], email.to
    assert_match /Daily Summary/, email.subject
    assert_match /#{locations.count}/, email.body.to_s
  end
end
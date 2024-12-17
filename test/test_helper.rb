# test/test_helper.rb

require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  fixtures :all
  
  # Helpers para tests geoespaciales
  def point_to_coordinates(point)
    return nil unless point
    [point.x, point.y]
  end
  
  def create_test_location(attributes = {})
    GeotrackerLocation.create!({
      project: projects(:projects_001),
      user: users(:users_001),
      coordinates: 'POINT(-73.935242 40.730610)',
      accuracy: 10.0
    }.merge(attributes))
  end
  
  def assert_coordinates_equal(expected, actual, message = nil)
    assert_in_delta expected[0], actual[0], 0.000001, "Longitude #{message}"
    assert_in_delta expected[1], actual[1], 0.000001, "Latitude #{message}"
  end
end

class ActionDispatch::IntegrationTest
  def log_user(login, password)
    post "/login", params: {
      username: login,
      password: password
    }
    follow_redirect!
    assert_equal '/', path
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  
  def assert_downloaded_file
    downloads = Dir["#{Dir.tmpdir}/downloads/*"]
    assert downloads.any?, "No file was downloaded"
  end
end
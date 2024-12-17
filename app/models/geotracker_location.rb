# app/models/geotracker_location.rb

class GeotrackerLocation < ActiveRecord::Base
  belongs_to :project
  belongs_to :issue, optional: true
  belongs_to :user

  validates :project, presence: true
  validates :user, presence: true
  validates :latitude, presence: true, 
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true, 
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  scope :active, -> { where(status: 'active') }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_issue, ->(issue_id) { where(issue_id: issue_id) }
  scope :recent, -> { order(created_at: :desc) }

  def self.within_bounds(sw_lat, sw_lng, ne_lat, ne_lng)
    where("ST_Within(geom, ST_MakeEnvelope(?, ?, ?, ?, 4326))",
          sw_lng, sw_lat, ne_lng, ne_lat)
  end

  def self.near(lat, lng, distance_in_meters)
    where("ST_DWithin(geom::geography, ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, ?)",
          lng, lat, distance_in_meters)
  end
end
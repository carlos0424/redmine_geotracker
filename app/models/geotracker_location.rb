# app/models/geotracker_location.rb

class GeotrackerLocation < ActiveRecord::Base
    # Asociaciones con modelos de Redmine
    belongs_to :project   # Proyecto asociado
    belongs_to :issue    # Issue asociado
    belongs_to :user     # Usuario que creó el registro
    
    # Validaciones
    validates :coordinates, presence: true
    validates :project_id, presence: true
    validates :user_id, presence: true
    
    # Enums para estados
    enum status: {
      pending: 'pending',       # Pendiente de verificación
      verified: 'verified',     # Verificado
      invalid: 'invalid',       # Marcado como inválido
      archived: 'archived'      # Archivado
    }
    
    # Scopes para consultas comunes
    scope :recent, -> { order(created_at: :desc) }
    scope :by_project, ->(project_id) { where(project_id: project_id) }
    scope :by_issue, ->(issue_id) { where(issue_id: issue_id) }
    scope :by_user, ->(user_id) { where(user_id: user_id) }
    scope :within_bounds, ->(sw_lat, sw_lng, ne_lat, ne_lng) {
      where("ST_Within(coordinates, ST_MakeEnvelope(?, ?, ?, ?, 4326))",
            sw_lng, sw_lat, ne_lng, ne_lat)
    }
    
    # Callbacks
    before_save :set_synchronized_at, if: :coordinates_changed?
    after_create :notify_related_users
    
    # Métodos de instancia
    
    # Obtiene la distancia a otro punto en metros
    def distance_to(lat, lng)
      query = "SELECT ST_Distance(
        coordinates::geography,
        ST_SetSRID(ST_MakePoint(#{lng}, #{lat}), 4326)::geography
      )"
      self.class.connection.execute(query).first['st_distance']
    end
    
    # Verifica si el punto está dentro de un radio dado
    def within_radius?(lat, lng, radius_meters)
      distance_to(lat, lng) <= radius_meters
    end
    
    private
    
    # Actualiza el timestamp de sincronización
    def set_synchronized_at
      self.synchronized_at = Time.current
    end
    
    # Notifica a usuarios relacionados sobre el nuevo registro
    def notify_related_users
      # TODO: Implementar sistema de notificaciones
    end
  end
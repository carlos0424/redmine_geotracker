class CreateGeotrackerLocations < ActiveRecord::Migration[7.0]
    def change
      # Creamos la tabla principal para almacenar las ubicaciones
      create_table :geotracker_locations do |t|
        # Referencias a entidades de Redmine
        t.references :project      # Referencia al proyecto
        t.references :issue       # Referencia al issue
        t.references :user        # Usuario que registró la ubicación
        
        # Campos geoespaciales usando PostGIS
        t.column :coordinates, :st_point, null: false  # Punto geográfico (latitud, longitud)
        t.column :accuracy, :float       # Precisión del GPS en metros
        t.column :altitude, :float       # Altitud en metros
        t.column :speed, :float         # Velocidad en m/s si está en movimiento
        
        # Campos de metadata
        t.string :device_id           # Identificador único del dispositivo
        t.string :connection_type     # Tipo de conexión (wifi, 4g, etc)
        t.string :battery_level       # Nivel de batería al momento del registro
        t.jsonb :additional_data     # Datos adicionales en formato JSON
        
        # Campos de control de flujo de trabajo
        t.string :status             # Estado del registro (pending, verified, etc)
        t.text :notes               # Notas adicionales
        t.boolean :is_manual, default: false  # Indica si fue un registro manual o automático
        
        # Campos de auditoría
        t.timestamps                # created_at y updated_at
        t.datetime :synchronized_at # Cuando se sincronizó con el servidor
      end
      
      # Índices para optimizar consultas
      add_index :geotracker_locations, :coordinates, using: :gist
      add_index :geotracker_locations, :device_id
      add_index :geotracker_locations, :status
      add_index :geotracker_locations, :synchronized_at
      
      # Índice compuesto para búsquedas comunes
      add_index :geotracker_locations, [:project_id, :issue_id, :created_at]
    end
  end
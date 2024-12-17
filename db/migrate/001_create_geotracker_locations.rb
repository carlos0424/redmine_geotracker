# db/migrate/001_create_geotracker_locations.rb

class CreateGeotrackerLocations < ActiveRecord::Migration[6.1]
  def up
    # Habilitar PostGIS si no está habilitado
    execute "CREATE EXTENSION IF NOT EXISTS postgis"

    create_table :geotracker_locations do |t|
      # Referencias a entidades de Redmine
      t.references :project, null: false
      t.references :issue
      t.references :user, null: false
      
      # Campos geoespaciales (usando geometry con SRID)
      t.column :latitude, :decimal, precision: 10, scale: 6
      t.column :longitude, :decimal, precision: 10, scale: 6
      t.column :accuracy, :decimal, precision: 10, scale: 2
      t.column :altitude, :decimal, precision: 10, scale: 2
      t.column :speed, :decimal, precision: 10, scale: 2
      t.column :heading, :decimal, precision: 10, scale: 2
      
      # Campos de metadatos
      t.string :device_id
      t.text :notes
      t.jsonb :metadata, default: {}
      
      # Campos de estado y control
      t.string :status, default: 'active'
      t.timestamps
    end
    
    # Crear índices
    add_index :geotracker_locations, [:latitude, :longitude]
    add_index :geotracker_locations, :status
    add_index :geotracker_locations, [:project_id, :created_at]

    # Añadir la columna espacial después de crear la tabla
    execute %{
      SELECT AddGeometryColumn('geotracker_locations', 'geom', 4326, 'POINT', 2);
      CREATE INDEX index_geotracker_locations_on_geom ON geotracker_locations USING GIST(geom);
    }

    # Trigger para mantener la columna geom actualizada
    execute %{
      CREATE OR REPLACE FUNCTION update_geom_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.geom := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_geotracker_location_geom
        BEFORE INSERT OR UPDATE
        ON geotracker_locations
        FOR EACH ROW
        EXECUTE PROCEDURE update_geom_column();
    }
  end

  def down
    execute "DROP TRIGGER IF EXISTS update_geotracker_location_geom ON geotracker_locations"
    execute "DROP FUNCTION IF EXISTS update_geom_column"
    drop_table :geotracker_locations
  end
end
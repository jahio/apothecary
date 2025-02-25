require "jennifer"
require "jennifer/adapter/postgres"
require "../utils/postgis"

module PharmacyInventoryAPI
  module Config
    # Configuration for Jennifer ORM with UUID support
    class_property db_url : String = 
      ENV["DATABASE_URL"]? || "postgres://postgres:postgres@localhost:5432/pharmacy_inventory"
    
    def self.setup_database
      Jennifer::Config.configure do |config|
        config.from_uri(db_url)
        config.logger.level = Logger::DEBUG
        
        # Configure UUID mappings
        config.adapter_mapping(
          UUID, 
          {
            "postgres" => Jennifer::Postgres::Adapter::UUID
          }
        )
        
        # Register custom converters for PostgreSQL specific types
        Jennifer::Config.register_adapter_type_converter("text[]", UUID)
        Jennifer::Config.register_adapter_type_converter("jsonb", UUID)
      end
    end
    
    # Helper method to generate a UUID
    def self.generate_uuid : String
      uuid = ""
      Jennifer::QueryBuilder.new.with_sql(
        "SELECT uuid_generate_v4()::text AS uuid"
      ).each_result_set do |rs|
        uuid = rs.read(String)
      end
      uuid
    end
    
    # Helper to refresh materialized views
    def self.refresh_materialized_views
      Jennifer::QueryBuilder.new.with_sql(
        "SELECT refresh_mat_views()"
      ).execute
    end
    
    # Convert a UUID to String (for compatibility with JSON)
    def self.uuid_to_string(uuid : UUID?) : String?
      uuid.try(&.to_s)
    end
    
    # Convert a String to UUID
    def self.string_to_uuid(str : String?) : UUID?
      str.try { |s| UUID.new(s) }
    end
  end
end
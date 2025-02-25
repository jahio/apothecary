require "jennifer"
require "jennifer/model/base"
require "../utils/postgis"

module PharmacyInventoryAPI
  class Pharmacy < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary64? | String, # UUID stored as string
      name: String,
      address1: String,
      address2: String?,
      city: String,
      state: String,
      zip_code: String,
      phone: String,
      email: String?,
      location: Point, # PostGIS point
      hours: JSON::Any?,
      amenities: Array(String)?,
      services: Array(String)?,
      api_key: String?,
      active: Bool,
      meta_data: JSON::Any?,
      created_at: Time,
      updated_at: Time
    )

    has_many :inventory, Inventory
    has_many :events, Event
    has_many :prices, Price
    has_many :api_keys, ApiKey

    # Validations
    validates_presence :name, :address1, :city, :state, :zip_code, :phone
    validates_format :phone, /^\+?[0-9\-\(\)\s]+$/
    validates_format :email, /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i, allow_blank: true
    validates_uniqueness :api_key, allow_blank: true

    # Find pharmacies within a radius
    def self.within_radius(lat : Float64, lng : Float64, radius_miles : Float64)
      # Use pharmacy_inventory_summary materialized view for better performance
      radius_meters = radius_miles * 1609.34
      
      pharmacy_ids = Jennifer::QueryBuilder.new.with_sql(
        "SELECT pharmacy_id FROM pharmacy_inventory_summary 
         WHERE ST_DWithin(location, ST_SetSRID(ST_MakePoint($1, $2), 4326), $3)",
        [lng, lat, radius_meters]
      ).pluck("pharmacy_id")
      
      ids = pharmacy_ids.map(&.as(String))
      return Pharmacy.all if ids.empty?
      
      Pharmacy.where { _id.in(ids) }
    end

    # Find pharmacies by zip code with inventory data
    def self.by_zip_code(zip : String)
      pharmacy_ids = Jennifer::QueryBuilder.new.with_sql(
        "SELECT pharmacy_id FROM pharmacy_inventory_summary WHERE zip_code = $1",
        [zip]
      ).pluck("pharmacy_id")
      
      ids = pharmacy_ids.map(&.as(String))
      return Pharmacy.where { _zip_code == zip } if ids.empty?
      
      Pharmacy.where { _id.in(ids) }
    end

    # Find pharmacies with specific services
    def self.with_services(services : Array(String))
      where("services @> $1::text[]", [services.to_json])
    end

    # Check if pharmacy has medication in stock
    def has_medication_in_stock?(medication_id : String) : Bool
      # Use the current_inventory view for better performance
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT COUNT(*) as count FROM current_inventory 
         WHERE pharmacy_id = $1 AND medication_id = $2",
        [id.to_s, medication_id]
      ).first
      
      result && result["count"].as(Int64) > 0
    end

    # Get current quantity of a medication
    def medication_quantity(medication_id : String) : Int32
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT quantity FROM current_inventory 
         WHERE pharmacy_id = $1 AND medication_id = $2",
        [id.to_s, medication_id]
      ).first
      
      result ? result["quantity"].as(Int32) : 0
    end

    # Get current cash price for a medication
    def current_cash_price(medication_id : String) : Float64?
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT cash_price FROM current_prices 
         WHERE pharmacy_id = $1 AND medication_id = $2",
        [id.to_s, medication_id]
      ).first
      
      result ? result["cash_price"].as(Float64) : nil
    end

    # Add a service to the pharmacy
    def add_service(service : String)
      current_services = services || [] of String
      return if current_services.includes?(service)
      
      new_services = current_services + [service]
      @services = new_services
      save
    end

    # Add an amenity to the pharmacy
    def add_amenity(amenity : String)
      current_amenities = amenities || [] of String
      return if current_amenities.includes?(amenity)
      
      new_amenities = current_amenities + [amenity]
      @amenities = new_amenities
      save
    end

    # Get metadata field
    def get_metadata(key : String)
      return nil unless meta_data
      
      meta_data.as_h[key]? rescue nil
    end

    # Set metadata field
    def set_metadata(key : String, value : JSON::Any::Type)
      current_data = meta_data.try(&.as_h) || {} of String => JSON::Any
      current_data[key] = JSON::Any.new(value)
      @meta_data = JSON::Any.new(current_data)
      save
    end

    # Generate a formatted address
    def full_address : String
      address = "#{address1}"
      address += ", #{address2}" if address2 && !address2.empty?
      address += ", #{city}, #{state} #{zip_code}"
      address
    end

    # Get distance from a point (in miles)
    def distance_from(lat : Float64, lng : Float64) : Float64
      # Use PostGIS to calculate distance
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT ST_Distance(
          ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, 
          location::geography
        ) / 1609.34 as distance", 
        [lng, lat]
      ).first

      result ? result["distance"].as(Float64) : 0.0
    end

    # Convert to JSON
    def to_json
      {
        id: id,
        name: name,
        address: full_address,
        phone: phone,
        email: email,
        location: {
          latitude: location.y,
          longitude: location.x
        },
        hours: hours,
        amenities: amenities,
        services: services,
        meta_data: meta_data,
        active: active
      }.to_json
    end
  end
end
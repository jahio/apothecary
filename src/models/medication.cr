require "jennifer"
require "jennifer/model/base"

module PharmacyInventoryAPI
  class Medication < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary64? | String, # UUID stored as string
      name: String,
      ndc_code: String?,
      rxcui: String?,
      identifiers: Array(String)?,
      route: String?,
      form: String?,
      strength: String?,
      generic_name: String?,
      brand_name: String?,
      additional_data: JSON::Any?,
      created_at: Time,
      updated_at: Time
    )

    has_many :inventory, Inventory
    has_many :events, Event
    has_many :prices, Price

    # Validations
    validates_presence :name
    validates_uniqueness :ndc_code, allow_blank: true

    # Find by any identifier or name
    def self.find_by_code_or_name(code_or_name : String)
      # For optimal performance, leverage the materialized view
      results = Jennifer::QueryBuilder.new.with_sql(
        "SELECT id FROM medication_search_index 
         WHERE to_tsvector('english', search_text) @@ plainto_tsquery('english', $1)",
        [code_or_name]
      ).pluck("id")
      
      ids = results.map(&.as(String))
      return Medication.all if ids.empty?
      
      Medication.where { _id.in(ids) }
    end

    # Get current inventory across all pharmacies
    def current_inventory
      # Use the current_inventory view for better performance
      Jennifer::QueryBuilder.new.with_sql(
        "SELECT * FROM current_inventory WHERE medication_id = $1",
        [id.to_s]
      )
    end

    # Get available pharmacies with inventory
    def available_pharmacies
      Pharmacy.join(Inventory) { _id == _pharmacy_id }
        .where { _medication_id == id }
        .where { _quantity > 0 }
    end

    # Get primary identifier
    def primary_identifier
      ndc_code || rxcui || "med-#{id}"
    end

    # Add an identifier to the identifiers array
    def add_identifier(identifier : String)
      current_identifiers = identifiers || [] of String
      return if current_identifiers.includes?(identifier)
      
      new_identifiers = current_identifiers + [identifier]
      @identifiers = new_identifiers
      save
    end

    # Get additional data field
    def get_additional_data(key : String)
      return nil unless additional_data
      
      additional_data.as_h[key]? rescue nil
    end

    # Set additional data field
    def set_additional_data(key : String, value : JSON::Any::Type)
      current_data = additional_data.try(&.as_h) || {} of String => JSON::Any
      current_data[key] = JSON::Any.new(value)
      @additional_data = JSON::Any.new(current_data)
      save
    end

    # Convert to JSON
    def to_json
      {
        id: id,
        name: name,
        ndc_code: ndc_code,
        rxcui: rxcui,
        identifiers: identifiers,
        route: route, 
        form: form,
        strength: strength,
        generic_name: generic_name,
        brand_name: brand_name,
        additional_data: additional_data
      }.to_json
    end
  end
end
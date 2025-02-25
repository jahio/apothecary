require "jennifer"
require "jennifer/model/base"

module PharmacyInventoryAPI
  class Inventory < Jennifer::Model::Base
    with_timestamps

    mapping(
      id: Primary64? | String, # UUID stored as string
      pharmacy_id: String,
      medication_id: String,
      quantity: Int32,
      unit: String,
      advertise_price: Bool,
      restock_threshold: Int32?,
      expiration_dates: JSON::Any?,
      location_data: JSON::Any?,
      updated_at: Time
    )

    belongs_to :pharmacy, Pharmacy
    belongs_to :medication, Medication

    # Validations
    validates_presence :pharmacy_id, :medication_id, :quantity, :unit
    validates_numericality :quantity, greater_or_equal_to: 0

    # Update inventory quantity
    def add_quantity(amount : Int32)
      return false if amount < 0

      @quantity += amount
      save
    end

    def remove_quantity(amount : Int32)
      return false if amount < 0 || amount > @quantity

      @quantity -= amount
      save
    end

    # Check if inventory is low
    def is_low? : Bool
      return false unless restock_threshold
      quantity <= restock_threshold
    end

    # Add expiration date information
    def add_expiration_date(lot : String, expiration : Time, quantity : Int32)
      current_data = expiration_dates.try(&.as_h) || {} of String => JSON::Any
      current_data[lot] = JSON::Any.new({
        "expiration" => expiration.to_s("%Y-%m-%d"),
        "quantity" => quantity
      })
      @expiration_dates = JSON::Any.new(current_data)
      save
    end

    # Set storage location in pharmacy
    def set_location(location_info : Hash(String, JSON::Any::Type))
      @location_data = JSON::Any.new(location_info)
      save
    end

    # Get current cash price
    def current_price : Price?
      # Use the current_prices view for better performance
      result = Jennifer::QueryBuilder.new.with_sql(
        "SELECT * FROM current_prices 
         WHERE pharmacy_id = $1 AND medication_id = $2", 
        [pharmacy_id, medication_id]
      ).first
      
      if result
        Price.new({
          id: result["price_id"],
          pharmacy_id: result["pharmacy_id"],
          medication_id: result["medication_id"],
          cash_price: result["cash_price"],
          unit: result["unit"],
          discount_programs: result["discount_programs"],
          insurance_coverage: result["insurance_coverage"],
          effective_date: result["effective_date"],
          end_date: nil
        })
      else
        nil
      end
    end

    # Get historical stock levels (last 3 months)
    def stock_history
      three_months_ago = Time.utc - 3.months
      
      # Use the recent_events materialized view for better performance if possible
      Event.where { 
        (_pharmacy_id == pharmacy_id) & 
        (_medication_id == medication_id) & 
        (_created_at >= three_months_ago) 
      }.order(created_at: :asc)
    end

    # Convert to JSON
    def to_json
      {
        id: id,
        pharmacy_id: pharmacy_id,
        medication
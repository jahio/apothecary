require "kemal"
require "json"
require "../models/*"
require "../services/*"
require "../config/*"

module PharmacyInventoryAPI
  module EventController
    extend self
    
    # Record receipt of medication inventory
    def record_receipt(env)
      # Parse request body
      request = parse_request_body(env)
      
      # Validate request parameters
      unless request["medication_id"]? && request["quantity"]? && request["unit"]?
        env.response.status_code = 400
        return {error: "Missing required parameters"}.to_json
      end
      
      # Get pharmacy from authentication middleware
      pharmacy_id = env.get("pharmacy_id").as(String)
      medication_id = request["medication_id"].as_s
      quantity = request["quantity"].as_i
      unit = request["unit"].as_s
      cash_price = request["cash_price"]?.try(&.as_f)
      advertise_price = request["advertise_price"]?.try(&.as_bool) || true
      
      # Optional extended parameters
      batch_info = request["batch_info"]?.try(&.as_h) || {} of String => JSON::Any
      location_data = request["location_data"]?.try(&.as_h) || {} of String => JSON::Any
      restock_threshold = request["restock_threshold"]?.try(&.as_i)
      
      # Validate quantities
      if quantity <= 0
        env.response.status_code = 400
        return {error: "Quantity must be positive"}.to_json
      end
      
      # Find or create inventory record
      inventory = Inventory.where { 
        (_pharmacy_id == pharmacy_id) & 
        (_medication_id == medication_id) 
      }.first
      
      # Create inventory if it doesn't exist
      if !inventory
        # Generate UUID for new inventory
        inventory_id = Config.generate_uuid
        
        # Build default values
        if !batch_info.empty?
          # Create a JSONB object for batch info
          batch_jsonb = JSON::Any.new(batch_info)
        end
        
        if !location_data.empty?
          # Create a JSONB object for location data
          location_jsonb = JSON::Any.new(location_data)
        end
        
        inventory = Inventory.new({
          id: inventory_id,
          pharmacy_id: pharmacy_id,
          medication_id: medication_id,
          quantity: 0,
          unit: unit,
          advertise_price: advertise_price,
          restock_threshold: restock_threshold,
          expiration_dates: batch_info.empty? ? nil : JSON::Any.new(batch_info),
          location_data: location_data.empty? ? nil : JSON::Any.new(location_data)
        })
        
        unless inventory.save
          env.response.status_code = 422
          return {error: "Failed to create inventory record", details: inventory.errors.to_h}.to_json
        end
      end
      
      # Create receipt event metadata
      metadata = request["metadata"]?.try(&.as_h) || {} of String => JSON::Any
      metadata["source"] = JSON::Any.new("api")
      metadata["timestamp"] = JSON::Any.new(Time.utc.to_s("%Y-%m-%d %H:%M:%S"))
      
      # Generate UUID for event
      event_id = Config.generate_uuid
      
      # Create receipt event
      event = Event.new({
        id: event_id,
        pharmacy_id: pharmacy_id,
        medication_id: medication_id,
        event_type: "receipt",
        quantity: quantity,
        unit: unit,
        batch_info: batch_info.empty? ? nil : JSON::Any.new(batch_info),
        metadata: JSON::Any.new(metadata)
      })
      
      unless event.save
        env.response.status_code = 422
        return {error: "Failed to create event", details: event.errors.to_h}.to_json
      end
      
      # Update inventory
      inventory.add_quantity(quantity)
      
      # Update price if provided
      if cash_price && cash_price > 0
        # Close current price record if it exists
        current_price = Price.where { 
          (_pharmacy_id == pharmacy_id) & 
          (_medication_id == medication_id) & 
          (_end_date == nil) 
        }.first
        
        # Process discount programs if provided
        discount_programs = request["discount_programs"]?.try(&.as_h) || {} of String => JSON::Any
        insurance_coverage = request["insurance_coverage"]?.try(&.as_h) || {} of String => JSON::Any
        
        if current_price && current_price.cash_price != cash_price
          current_price.end_date = Time.utc
          current_price.save
          
          # Generate UUID for new price
          price_id = Config.generate_uuid
          
          # Create new price record
          new_price = Price.new({
            id: price_id,
            pharmacy_id: pharmacy_id,
            medication_id: medication_id,
            cash_price: cash_price,
            unit: unit,
            discount_programs: discount_programs.empty? ? nil : JSON::Any.new(discount_programs),
            insurance_coverage: insurance_coverage.empty? ? nil : JSON::Any.new(insurance_coverage),
            effective_date: Time.utc
          })
          
          unless new_price.save
            env.response.status_code = 422
            return {error: "Failed to update price", details: new_price.errors.to_h}.to_json
          end
        elsif !current_price
          # Generate UUID for new price
          price_id = Config.generate_uuid
          
          # Create first price record
          new_price = Price.new({
            id: price_id,
            pharmacy_id: pharmacy_id,
            medication_id: medication_id,
            cash_price: cash_price,
            unit: unit,
            discount_programs: discount_programs.empty? ? nil : JSON::Any.new(discount_programs),
            insurance_coverage: insurance_coverage.empty? ? nil : JSON::Any.new(insurance_coverage),
            effective_date: Time.utc
          })
          
          unless new_price.save
            env.response.status_code = 422
            return {error: "Failed to create price", details: new_price.errors.to_h}.to_json
          end
        end
        
        # Update advertise_price flag
        inventory.advertise_price = advertise_price
        inventory.save
      end
      
      # Refresh materialized views in background
      spawn do
        begin
          Config.refresh_materialized_views
        rescue e
          # Log error but don't fail the request
          puts "Error refreshing materialized views: #{e.message}"
        end
      end
      
      {
        success: true,
        event_id: event.id,
        current_quantity: inventory.quantity,
        medication_id: medication_id,
        pharmacy_id: pharmacy_id
      }.to_json
    end
    
    # Record reservation of medication
    def record_reserve(env)
      # Parse request body
      request = parse_request_body(env)
      
      # Validate request parameters
      unless request["medication_id"]? && request["quantity"]? && request["unit"]?
        env.response.status_code = 400
        return {error: "Missing required parameters"}.to_json
      end
      
      # Get pharmacy from authentication middleware
      pharmacy_id = env.get("pharmacy_id").as(String)
      medication_id = request["medication_id"].as_s
      quantity = request["quantity"].as_i
      unit = request["unit"].as_s
      
      # Validate quantities
      if quantity <= 0
        env.response.status_code = 400
        return {error: "Quantity must be positive"}.to_json
      end
      
      # Find inventory record
      inventory = Inventory.where { 
        (_pharmacy_id == pharmacy_id) & 
        (_medication_id == medication_id) 
      }.first
      
      # Check if enough inventory exists
      if !inventory || inventory.quantity < quantity
        env.response.status_code = 400
        return {
          error: "Insufficient inventory", 
          available: inventory ? inventory.quantity : 0,
          requested: quantity
        }.to_json
      end
      
      # Create event metadata
      metadata = request["metadata"]?.try(&.as_h) || {} of String => JSON::Any
      metadata["source"] = JSON::Any.new("api")
      metadata["timestamp"] = JSON::Any.new(Time.utc.to_s("%Y-%m-%d %H:%M:%S"))
      
      # Generate UUID for event
      event_id = Config.generate_uuid
      
      # Create reserve event
      event = Event.new({
        id: event_id,
        pharmacy_id: pharmacy_id,
        medication_id: medication_id,
        event_type: "reserve",
        quantity: quantity,
        unit: unit,
        metadata: JSON::Any.new(metadata)
      })
      
      unless event.save
        env.response.status_code = 422
        return {error: "Failed to create event", details: event.errors.to_h}.to_json
      end
      
      # Update inventory
      inventory.remove_quantity(quantity)
      
      # Refresh materialized views in background
      spawn do
        begin
          Config.refresh_materialized_views
        rescue e
          # Log error but don't fail the request
          puts "Error refreshing materialized views: #{e.message}"
        end
      end
      
      {
        success: true,
        event_id: event.id,
        current_quantity: inventory.quantity,
        medication_id: medication_id,
        pharmacy_id: pharmacy_id
      }.to_json
    end
    
    # Record pickup of medication
    def record_pickup(env)
      # Parse request body
      request = parse_request_body(env)
      
      # Validate request parameters
      unless request["medication_id"]? && request["quantity"]? && request["unit"]?
        env.response.status_code = 400
        return {error: "Missing required parameters"}.to_json
      end
      
      # Get pharmacy from authentication middleware
      pharmacy_id = env.get("pharmacy_id").as(String)
      medication_id = request["medication_id"].as_s
      quantity = request["quantity"].as_i
      unit = request["unit"].as_s
      patient_cost = request["patient_cost"]?.try(&.as_f) || 0.0
      insurance_paid = request["insurance_paid"]?.try(&.as_f) || 0.0
      
      # Validate quantities
      if quantity <= 0
        env.response.status_code = 400
        return {error: "Quantity must be positive"}.to_json
      end
      
      # Create event metadata
      metadata = request["metadata"]?.try(&.as_h) || {} of String => JSON::Any
      metadata["source"] = JSON::Any.new("api")
      metadata["timestamp"] = JSON::Any.new(Time.utc.to_s("%Y-%m-%d %H:%M:%S"))
      
      # Generate UUID for event
      event_id = Config.generate_uuid
      
      # Create pickup event
      event = Event.new({
        id: event_id,
        pharmacy_id: pharmacy_id,
        medication_id: medication_id,
        event_type: "pickup",
        quantity: quantity,
        unit: unit,
        patient_cost: patient_cost,
        insurance_paid: insurance_paid,
        metadata: JSON::Any.new(metadata)
      })
      
      unless event.save
        env.response.status_code = 422
        return {error: "Failed to create event", details: event.errors.to_h}.to_json
      end
      
      # No need to update inventory - reservation already reduced it
      
      # Refresh materialized views in background
      spawn do
        begin
          Config.refresh_materialized_views
        rescue e
          # Log error but don't fail the request
          puts "Error refreshing materialized views: #{e.message}"
        end
      end
      
      {
        success: true,
        event_id: event.id,
        medication_id: medication_id,
        pharmacy_id: pharmacy_id,
        patient_cost: patient_cost,
        insurance_paid: insurance_paid
      }.to_json
    end
    
    # Helper method to parse JSON request body
    private def parse_request_body(env)
      body = env.request.body.not_nil!.gets_to_end
      
      begin
        JSON.parse(body)
      rescue e
        env.response.status_code = 400
        {error: "Invalid JSON request body"}.to_json
        JSON.parse("{}")
      end
    end
  end
end
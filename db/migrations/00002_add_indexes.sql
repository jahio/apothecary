-- Add indexes to speed up queries

-- Medications indexes
CREATE INDEX medications_name_idx ON medications (name);
CREATE INDEX medications_generic_name_idx ON medications (generic_name);
CREATE INDEX medications_brand_name_idx ON medications (brand_name);
CREATE INDEX medications_ndc_idx ON medications (ndc_code);
CREATE INDEX medications_identifiers_idx ON medications USING GIN (identifiers);
CREATE INDEX medications_additionaldata_idx ON medications USING GIN (additional_data);

-- Pharmacies indexes
CREATE INDEX pharmacies_location_idx ON pharmacies USING GIST (location);
CREATE INDEX pharmacies_zip_idx ON pharmacies (zip_code);
CREATE INDEX pharmacies_state_city_idx ON pharmacies (state, city);
CREATE INDEX pharmacies_services_idx ON pharmacies USING GIN (services);
CREATE INDEX pharmacies_amenities_idx ON pharmacies USING GIN (amenities);
CREATE INDEX pharmacies_hours_idx ON pharmacies USING GIN (hours);
CREATE INDEX pharmacies_metadata_idx ON pharmacies USING GIN (meta_data);

-- Events indexes
CREATE INDEX events_pharmacy_medication_idx ON events (pharmacy_id, medication_id);
CREATE INDEX events_type_created_idx ON events (event_type, created_at);
CREATE INDEX events_medication_created_idx ON events (medication_id, created_at);
CREATE INDEX events_created_idx ON events (created_at DESC);
CREATE INDEX events_metadata_idx ON events USING GIN (metadata);
CREATE INDEX events_batchinfo_idx ON events USING GIN (batch_info);

-- Inventory indexes
CREATE INDEX inventory_pharmacy_idx ON inventory (pharmacy_id);
CREATE INDEX inventory_medication_idx ON inventory (medication_id);
CREATE INDEX inventory_quantity_idx ON inventory (quantity) WHERE quantity > 0;
CREATE INDEX inventory_locationdata_idx ON inventory USING GIN (location_data);
CREATE INDEX inventory_expirationdata_idx ON inventory USING GIN (expiration_dates);

-- Prices indexes
CREATE INDEX prices_pharmacy_medication_idx ON prices (pharmacy_id, medication_id);
CREATE INDEX prices_current_idx ON prices (pharmacy_id, medication_id, end_date) 
  WHERE end_date IS NULL;
CREATE INDEX prices_effectivedate_idx ON prices (effective_date);
CREATE INDEX prices_cashprice_idx ON prices (cash_price);
CREATE INDEX prices_discountprograms_idx ON prices USING GIN (discount_programs);
CREATE INDEX prices_insurancecoverage_idx ON prices USING GIN (insurance_coverage);

-- API keys indexes
CREATE INDEX apikeys_pharmacy_idx ON api_keys (pharmacy_id);
CREATE INDEX apikeys_active_idx ON api_keys (active);
CREATE INDEX apikeys_permissions_idx ON api_keys USING GIN (permissions);
CREATE INDEX apikeys_usagedata_idx ON api_keys USING GIN (usage_data);

-- Create scheduled task to refresh materialized views
CREATE OR REPLACE FUNCTION create_refresh_mat_views_job()
RETURNS void AS $$
BEGIN
    PERFORM cron.schedule('refresh_mat_views_job', '0 * * * *', 'SELECT refresh_mat_views()');
END;
$$ LANGUAGE plpgsql;

-- This requires pg_cron extension to be installed
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT create_refresh_mat_views_job();
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Medications table
CREATE TABLE medications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  ndc_code VARCHAR(50) UNIQUE,  -- National Drug Code
  rxcui VARCHAR(50),            -- RxNorm Concept Unique Identifier
  identifiers TEXT[],           -- Array of additional identifiers
  route VARCHAR(100),           -- Route of administration
  form VARCHAR(100),            -- Dosage form (tablet, capsule, etc)
  strength VARCHAR(100),        -- Dosage strength
  generic_name VARCHAR(255),
  brand_name VARCHAR(255),
  additional_data JSONB,        -- For extensible properties
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Pharmacies table
CREATE TABLE pharmacies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(255) NOT NULL,
  address1 VARCHAR(255) NOT NULL,
  address2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(50) NOT NULL,
  zip_code VARCHAR(20) NOT NULL,
  phone VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  location GEOGRAPHY(POINT, 4326) NOT NULL, -- PostGIS geography point
  hours JSONB,                              -- Store hours as JSONB
  amenities TEXT[],                         -- Array of pharmacy amenities
  services TEXT[],                          -- Array of pharmacy services
  api_key VARCHAR(255) UNIQUE,              -- API key for this pharmacy
  active BOOLEAN NOT NULL DEFAULT TRUE,
  meta_data JSONB,                          -- For extensible properties
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Inventory table - current inventory levels
CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  unit VARCHAR(50) NOT NULL,                -- unit of measurement (pill, ml, etc)
  advertise_price BOOLEAN NOT NULL DEFAULT TRUE,
  restock_threshold INTEGER,                -- For low stock alerts
  expiration_dates JSONB,                   -- JSONB with batch/lot expiration info
  location_data JSONB,                      -- Storage location in pharmacy
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  UNIQUE(pharmacy_id, medication_id)
);

-- Events table - receipt, reservation, pickup events
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  event_type VARCHAR(50) NOT NULL CHECK (event_type IN ('receipt', 'reserve', 'pickup')),
  quantity INTEGER NOT NULL,
  unit VARCHAR(50) NOT NULL,
  patient_cost DECIMAL(10, 2),              -- Only for pickup events
  insurance_paid DECIMAL(10, 2),            -- Only for pickup events
  batch_info JSONB,                         -- Batch/lot information
  metadata JSONB,                           -- Additional event metadata
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Prices table - historical prices
CREATE TABLE prices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID NOT NULL REFERENCES pharmacies(id) ON DELETE CASCADE,
  medication_id UUID NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
  cash_price DECIMAL(10, 2) NOT NULL,
  unit VARCHAR(50) NOT NULL,
  discount_programs JSONB,                 -- Available discount program info
  insurance_coverage JSONB,                -- Common insurance coverage info
  effective_date TIMESTAMP NOT NULL DEFAULT NOW(),
  end_date TIMESTAMP,                      -- NULL for current price
  UNIQUE(pharmacy_id, medication_id, effective_date)
);

-- API keys table - for authentication
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pharmacy_id UUID REFERENCES pharmacies(id) ON DELETE CASCADE,
  key VARCHAR(255) UNIQUE NOT NULL,
  description VARCHAR(255),
  permissions TEXT[],                      -- Array of permission strings
  is_admin BOOLEAN NOT NULL DEFAULT FALSE,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  usage_data JSONB,                        -- Track API usage patterns
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  last_used_at TIMESTAMP
);

-- Create views and materialized views for performance

-- Current prices view - easier access to current prices
CREATE VIEW current_prices AS
SELECT p.id AS price_id, p.pharmacy_id, p.medication_id, p.cash_price, p.unit, 
       p.discount_programs, p.insurance_coverage, p.effective_date
FROM prices p
WHERE p.end_date IS NULL;

-- Current inventory view - easier access to in-stock medications
CREATE VIEW current_inventory AS
SELECT i.id AS inventory_id, i.pharmacy_id, i.medication_id, 
       m.name AS medication_name, m.generic_name, m.brand_name, m.ndc_code,
       i.quantity, i.unit, i.advertise_price
FROM inventory i
JOIN medications m ON i.medication_id = m.id
WHERE i.quantity > 0;

-- Medication search materialized view - optimized for frequent searches
CREATE MATERIALIZED VIEW medication_search_index AS
SELECT m.id, m.name, m.ndc_code, m.rxcui, m.generic_name, m.brand_name, 
       m.form, m.strength, m.route,
       array_to_string(ARRAY[m.name, m.generic_name, m.brand_name, m.ndc_code, m.rxcui], ' ') AS search_text
FROM medications m;

CREATE INDEX medication_search_idx ON medication_search_index USING gin(to_tsvector('english', search_text));

-- Pharmacy inventory summary materialized view - for quick availability checks
CREATE MATERIALIZED VIEW pharmacy_inventory_summary AS
SELECT 
    p.id AS pharmacy_id,
    p.name AS pharmacy_name,
    p.location,
    p.zip_code,
    COUNT(DISTINCT i.medication_id) AS unique_medications_count,
    SUM(CASE WHEN i.quantity > 0 THEN 1 ELSE 0 END) AS in_stock_count
FROM pharmacies p
LEFT JOIN inventory i ON p.id = i.pharmacy_id
WHERE p.active = true
GROUP BY p.id, p.name, p.location, p.zip_code;

CREATE INDEX pharmacy_inventory_location_idx ON pharmacy_inventory_summary USING GIST(location);
CREATE INDEX pharmacy_inventory_zip_idx ON pharmacy_inventory_summary(zip_code);

-- Recent events materialized view - for quick access to recent activity
CREATE MATERIALIZED VIEW recent_events AS
SELECT e.id, e.pharmacy_id, e.medication_id, e.event_type, e.quantity, e.created_at,
       m.name AS medication_name, p.name AS pharmacy_name
FROM events e
JOIN medications m ON e.medication_id = m.id
JOIN pharmacies p ON e.pharmacy_id = p.id
WHERE e.created_at > (NOW() - INTERVAL '30 days')
ORDER BY e.created_at DESC;

-- Function to refresh materialized views
CREATE OR REPLACE FUNCTION refresh_mat_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY medication_search_index;
    REFRESH MATERIALIZED VIEW CONCURRENTLY pharmacy_inventory_summary;
    REFRESH MATERIALIZED VIEW CONCURRENTLY recent_events;
END;
$$ LANGUAGE plpgsql;
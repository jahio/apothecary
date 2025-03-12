# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_12_152701) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "hstore"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "inventory_event_operation", ["pickup", "return_to_shelf", "return_to_manufacturer", "destroyed", "theft", "law_enforcement_action", "other"]

  create_table "drugs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.text "form", null: false
    t.text "administration_route", null: false
    t.text "description", null: false
    t.text "dea_identifier", null: false
    t.integer "schedule", null: false
    t.boolean "addictive"
    t.boolean "stimulant"
    t.boolean "depressant"
    t.boolean "opioid"
    t.boolean "painkiller"
    t.text "dosage_unit", null: false
    t.bigint "dosage_qty", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["addictive"], name: "index_drugs_on_addictive"
    t.index ["dea_identifier", "addictive"], name: "index_drugs_on_dea_identifier_and_addictive"
    t.index ["dea_identifier", "name"], name: "index_drugs_on_dea_identifier_and_name"
    t.index ["dea_identifier", "opioid"], name: "index_drugs_on_dea_identifier_and_opioid"
    t.index ["dea_identifier", "schedule"], name: "index_drugs_on_dea_identifier_and_schedule"
    t.index ["dea_identifier"], name: "index_drugs_on_dea_identifier"
    t.index ["depressant", "addictive"], name: "index_drugs_on_depressant_and_addictive"
    t.index ["depressant"], name: "index_drugs_on_depressant"
    t.index ["dosage_qty"], name: "index_drugs_on_dosage_qty"
    t.index ["dosage_unit"], name: "index_drugs_on_dosage_unit"
    t.index ["form"], name: "index_drugs_on_form"
    t.index ["name", "dosage_qty", "dosage_unit"], name: "index_drugs_on_name_and_dosage_qty_and_dosage_unit"
    t.index ["name", "form"], name: "index_drugs_on_name_and_form"
    t.index ["name"], name: "index_drugs_on_name"
    t.index ["opioid", "painkiller"], name: "index_drugs_on_opioid_and_painkiller"
    t.index ["opioid"], name: "index_drugs_on_opioid"
    t.index ["painkiller"], name: "index_drugs_on_painkiller"
    t.index ["schedule", "addictive"], name: "index_drugs_on_schedule_and_addictive"
    t.index ["schedule"], name: "index_drugs_on_schedule"
    t.index ["stimulant", "addictive"], name: "index_drugs_on_stimulant_and_addictive"
    t.index ["stimulant"], name: "index_drugs_on_stimulant"
  end

  create_table "inventories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "drug_id", null: false
    t.uuid "pharmacy_id", null: false
    t.bigint "physical_qty", default: 0, null: false
    t.bigint "qty_reserved", default: 0, null: false
    t.float "price_per_unit", default: 1.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drug_id"], name: "index_inventories_on_drug_id"
    t.index ["pharmacy_id"], name: "index_inventories_on_pharmacy_id"
    t.index ["physical_qty"], name: "index_inventories_on_physical_qty"
    t.index ["price_per_unit"], name: "index_inventories_on_price_per_unit"
    t.index ["qty_reserved"], name: "index_inventories_on_qty_reserved"
  end

  create_table "inventory_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "pharmacy_id"
    t.uuid "drug_id"
    t.bigint "qty", default: 0, null: false
    t.enum "operation", default: "pickup", null: false, enum_type: "inventory_event_operation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["drug_id"], name: "index_inventory_events_on_drug_id"
    t.index ["operation"], name: "index_inventory_events_on_operation"
    t.index ["pharmacy_id"], name: "index_inventory_events_on_pharmacy_id"
    t.index ["qty"], name: "index_inventory_events_on_qty"
  end

  create_table "pharmacies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name", null: false
    t.text "address", null: false
    t.text "city", null: false
    t.text "state", null: false
    t.text "zip", null: false
    t.text "lat"
    t.text "lon"
    t.text "phones_human", null: false, array: true
    t.text "phones_fax", null: false, array: true
    t.jsonb "personnel", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address", "lat", "lon", "zip"], name: "index_pharmacies_on_address_and_lat_and_lon_and_zip"
    t.index ["address", "state", "zip"], name: "index_pharmacies_on_address_and_state_and_zip"
    t.index ["address"], name: "index_pharmacies_on_address"
    t.index ["city", "state", "zip"], name: "index_pharmacies_on_city_and_state_and_zip"
    t.index ["city"], name: "index_pharmacies_on_city"
    t.index ["lat", "lon"], name: "index_pharmacies_on_lat_and_lon"
    t.index ["name", "city", "state"], name: "index_pharmacies_on_name_and_city_and_state"
    t.index ["name", "city", "zip"], name: "index_pharmacies_on_name_and_city_and_zip"
    t.index ["name"], name: "index_pharmacies_on_name"
    t.index ["personnel"], name: "index_pharmacies_on_personnel"
    t.index ["phones_fax"], name: "index_pharmacies_on_phones_fax"
    t.index ["phones_human"], name: "index_pharmacies_on_phones_human"
    t.index ["state"], name: "index_pharmacies_on_state"
    t.index ["zip"], name: "index_pharmacies_on_zip"
  end

  add_foreign_key "inventories", "drugs"
  add_foreign_key "inventories", "pharmacies"
  add_foreign_key "inventory_events", "drugs"
  add_foreign_key "inventory_events", "pharmacies"
end

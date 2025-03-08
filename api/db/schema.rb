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

ActiveRecord::Schema[8.0].define(version: 2025_03_08_050115) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "pharmacies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.text "name"
    t.text "address"
    t.text "city"
    t.text "state"
    t.text "zip"
    t.text "lat"
    t.text "lon"
    t.text "phones_human", array: true
    t.text "phones_fax", array: true
    t.jsonb "personnel"
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
end

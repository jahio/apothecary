class CreatePharmacies < ActiveRecord::Migration[8.0]
  def change
    create_table :pharmacies, id: :uuid do |t|
      t.text        :name, index: true, null: false
      t.text        :address, index: true, null: false
      t.text        :city, index: true, null: false
      t.text        :state, index: true, null: false
      t.text        :zip, index: true, null: false
      t.text        :lat
      t.text        :lon
      t.text        :phones_human, array: true, index: true, null: false
      t.text        :phones_fax, array: true, index: true, null: false
      t.jsonb       :personnel, index: true, null: false
      t.timestamps
    end

    # Indexes
    add_index :pharmacies, [:lat, :lon]
    add_index :pharmacies, [:city, :state, :zip]
    add_index :pharmacies, [:name, :city, :state]
    add_index :pharmacies, [:name, :city, :zip]
    add_index :pharmacies, [:address, :state, :zip]
    add_index :pharmacies, [:address, :lat, :lon, :zip]
  end
end

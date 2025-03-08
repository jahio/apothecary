class CreatePharmacies < ActiveRecord::Migration[8.0]
  def change
    create_table :pharmacies, id: :uuid do |t|
      t.text        :name
      t.text        :address
      t.text        :city
      t.text        :state
      t.text        :zip
      t.text        :lat
      t.text        :lon
      t.text        :phones_human, array: true
      t.text        :phones_fax, array: true
      t.jsonb       :personnel
      t.timestamps
    end

    # Indexes
    add_index :pharmacies, :name
    add_index :pharmacies, :address
    add_index :pharmacies, :city
    add_index :pharmacies, :state
    add_index :pharmacies, :zip
    add_index :pharmacies, [:lat, :lon]
    add_index :pharmacies, :phones_human
    add_index :pharmacies, :phones_fax
    add_index :pharmacies, :personnel
    add_index :pharmacies, [:city, :state, :zip]
    add_index :pharmacies, [:name, :city, :state]
    add_index :pharmacies, [:name, :city, :zip]
    add_index :pharmacies, [:address, :state, :zip]
    add_index :pharmacies, [:address, :lat, :lon, :zip]
  end
end

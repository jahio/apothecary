class CreateDrugs < ActiveRecord::Migration[8.0]
  def change
    create_table :drugs, id: :uuid do |t|
      t.text         :name, index: true, null: false
      t.text         :form, index: true, null: false # e.g. liquid, pill, mist, etc.
      t.text         :administration_route, null: false # injected, oral, inhaled...
      t.text         :description, null: false # basic description for the public
      t.text         :dea_identifier, index: true, null: false # how the DEA identifies this drug
      t.integer      :schedule, index: true, null: false # Schedule 1-4 classification (legal class)
      t.boolean      :addictive, index: true # Is it addictive?
      t.boolean      :stimulant, index: true # Is it a stimulant?
      t.boolean      :depressant, index: true # Is it a CNS depressant?
      t.boolean      :opioid, index: true # Is this an opioid?
      t.boolean      :painkiller, index: true # Is it a pain killer of some kind?
      t.text         :dosage_unit, index: true, null: false # Unit of measure for dosage - milligrams, milliliters, etc.
      t.bigint       :dosage_qty, index: true, null: false # Dosage quantity - how many mg or mcg or ml or whatever
      t.timestamps
    end

    # Indexes - most of these are composite to speed combination searches
    add_index :drugs, [:opioid, :painkiller]
    add_index :drugs, [:stimulant, :addictive]
    add_index :drugs, [:depressant, :addictive]
    add_index :drugs, [:schedule, :addictive]
    add_index :drugs, [:dea_identifier, :addictive]
    add_index :drugs, [:dea_identifier, :opioid]
    add_index :drugs, [:dea_identifier, :schedule]
    add_index :drugs, [:dea_identifier, :name]

    # This one is likely to be used a lot. Though it wouldn't be in
    # this DB, an example could be:
    #   Melatonin, Liquid         (or)        Melatonin, Tablet
    add_index :drugs, [:name, :form]

    # This one's going to get used to figure out what strength of
    # medication somebody needs - e.g. 40mg or 80mg tablets?
    add_index :drugs, [:name, :dosage_qty, :dosage_unit]

  end
end

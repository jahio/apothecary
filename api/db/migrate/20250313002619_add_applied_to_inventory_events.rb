class AddAppliedToInventoryEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :inventory_events, :applied_by_updater_at, :datetime, null: true, default: nil
    add_index :inventory_events, :applied_by_updater_at
  end
end

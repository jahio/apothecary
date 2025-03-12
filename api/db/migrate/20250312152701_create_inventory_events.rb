class CreateInventoryEvents < ActiveRecord::Migration[8.0]
  def change
    create_enum :inventory_event_operation, InventoryEvent::VALID_OPERATIONS
    create_table :inventory_events, id: :uuid do |t|
      t.references :pharmacy, type: :uuid, foreign_key: true, index: true
      t.references :drug, type: :uuid, foreign_key: true, index: true
      t.bigint :qty, index: true, null: false, default: 0
      t.enum :operation, enum_type: :inventory_event_operation, default: "pickup", null: false, index: true
      t.timestamps
    end
  end
end

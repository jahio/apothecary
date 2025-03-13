class CreateInventoriesTxes < ActiveRecord::Migration[8.0]
  def change
    create_view :inventories_txes, materialized: true
    add_index :inventories_txes, :id, unique: true
  end
end

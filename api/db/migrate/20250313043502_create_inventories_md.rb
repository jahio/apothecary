class CreateInventoriesMd < ActiveRecord::Migration[8.0]
  def change
    create_view :inventories_mds, materialized: true
    add_index :inventories_mds, :id, unique: true
  end
end

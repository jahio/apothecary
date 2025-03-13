class CreateInventoriesVa < ActiveRecord::Migration[8.0]
  def change
    create_view :inventories_vas, materialized: true
    add_index :inventories_vas, :id, unique: true
  end
end

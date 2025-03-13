class CreateInventoriesMds < ActiveRecord::Migration[8.0]
  def change
    create_view :inventories_mds, materialized: true
  end
end

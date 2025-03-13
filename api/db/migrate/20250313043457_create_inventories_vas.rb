class CreateInventoriesVas < ActiveRecord::Migration[8.0]
  def change
    create_view :inventories_vas, materialized: true
  end
end

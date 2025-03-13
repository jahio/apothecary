require "active_support/concern"

# Geographically Distributed Inventory (Concern)
module GdiConcern
  extend ActiveSupport::Concern

  included do
    def self.refresh
      Scenic.database.refresh_materialized_view(table_name, concurrently: false, cascade: true)
    end

    def readonly?
      true
    end
  end
end

class EnableNeededExtensions < ActiveRecord::Migration[8.0]
  def change
    %w[pgcrypto hstore].each do |ext|
      enable_extension ext unless extension_enabled?(ext)
    end
  end
end

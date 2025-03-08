class CreateInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :inventories, id: :uuid do |t|
      t.references :drug, foreign_key: true, type: :uuid, index: true
      t.references :pharmacy, foreign_key: true, type: :uuid, index: true

      # This is how many units are physically on-hand, regardless of
      # whether they're already in the bottle waiting for another patient
      # to pick them up or not. Until they physically leave the store, we're
      # counting them as "physical quantity on hand".
      t.bigint     :physical_qty, index: true

      # This is how many are reserved for patients waiting to come pick
      # them up, or are for whatever other reason considered not available
      # to be prescribed (maybe the shipment had a damaged box in there, a
      # bad batch subject to recall, etc.) Final metrics the end user sees
      # will subtract this from the physical quantity on hand while still
      # retaining the precision for reporting reasons.
      t.bigint     :qty_reserved, index: true

      # If by some miracle could ever get laws passed requiring these folks
      # to report their out-of-pocket cash pricing, flat, no gimmicks, tricks,
      # programs or ads, we could actually start comparing prices. I'm making
      # room for that fictional perfect world even though I know it's the last
      # thing the greedy SOBs running things want...
      t.float      :price_per_unit, index: true

      # In other tables and sets of views, we'll track the "flow" of events as
      # their inventory software reports drugs leaving the premises and shipments
      # of new/refill product arriving day by day. This way we can keep an eye on
      # local inventories as they're sold and restocked, as well as a pulse on the
      # overall economic supply and demand flow for reporting and overall public
      # health monitoring purposes.

      t.timestamps
    end
  end
end

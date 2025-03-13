class InventoryUpdaterJob < ApplicationJob
  queue_as :default

  #
  # This particular job is responsible for taking all the inventory updates
  # that have come in since the last run and applying the math to the database.
  #
  def perform(*args)
    # This is an overly simplistic implementation that would lag behind in the
    # real world, but for our purposes, good 'nuff:
    InventoryEvent.where(applied_by_updater_at: nil).each_with_index do |evt, _i|
      inv = Inventory.where(drug: evt.drug, pharmacy: evt.pharmacy)

      if inv.respond_to?(evt.operation.to_sym)
        # Look at InventoryEvent::VALID_OPERATIONS - a frozen array - for methods
        # that will be defined on the Inventory class. When any such event happens,
        # the same method will be called on the inventory class, passing the quantity
        # in as an argument. This way, we can "trust" the object knows what to increment
        # and decrement according to its own method call.
        inv.send(evt.operation.to_sym, evt.qty)
      end

      evt.update!(applied_by_updater_at: Time.now.utc)
    end
  end
end

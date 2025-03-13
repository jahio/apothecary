class Inventory < ApplicationRecord
  belongs_to :pharmacy
  belongs_to :drug

  validates :physical_qty, :qty_reserved, :price_per_unit, presence: true

  # Called when drugs are picked up by patients
  def pickup(qty)
    update!(physical_qty: physical_qty - qty, qty_reserved: qty_reserved - qty)
  end

  # Called when a drug is not picked up by a patient, instead
  # the staff returns it to the shelf to be filled for someone else
  def return_to_shelf(qty)
    # Recall that physical_qty INCLUDES the amount "reserved" for patients
    # In this case, the total amount on-site hasn't changed, but we do want
    # to indicate that the amount reserved for patients has indeed decreased
    # since now that's available for others to be filled.
    update!(qty_reserved: qty_reserved - qty)
  end

  # Called when a drug needs to be, for whatever reason, returned
  # to its manufacturer. Maybe a recall was issued, maybe there's
  # something wrong with the shipment the staff received, etc.
  def return_to_manufacturer(qty)
    update!(physical_qty: physical_qty - qty)
  end

  # Called when the staff intentionally destroy a shipment of drugs
  # or otherwise flag that the medication was destroyed for some reason
  # This may be in cooperation with a legal order, for safety reasons,
  # perhaps as part of a natural disaster, etc.
  def destroyed(qty)
    update!(physical_qty: physical_qty - qty)
  end

  # Called when staff report medication stolen; this is somewhere
  # you'd want to create logs and paper trail for DEA/FBI/local PD
  # to investigate
  def theft(qty)
    update!(physical_qty: physical_qty - qty)
  end

  # Called when some other law enforcement action (not specified)
  # occurs for whatever reason. This is always a loss of medication,
  # they never bring property back (and you couldn't re-use it anyway...)
  def law_enforcement_action(qty)
    update!(physical_qty: physical_qty - qty)
  end
end

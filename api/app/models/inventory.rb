class Inventory < ApplicationRecord
  belongs_to :pharmacy
  belongs_to :drug

  validates :physical_qty, :qty_reserved, :price_per_unit, presence: true
end

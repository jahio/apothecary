class InventoryEvent < ApplicationRecord
  VALID_OPERATIONS = %w[
    pickup
    return_to_shelf
    return_to_manufacturer
    destroyed
    theft
    law_enforcement_action
    other
  ].freeze

  belongs_to :pharmacy
  belongs_to :drug
  validates :qty, presence: true, numericality: true
  validates :operation, presence: true
end

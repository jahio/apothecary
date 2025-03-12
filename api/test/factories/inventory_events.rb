FactoryBot.define do
  factory :inventory_event do
    pharmacy
    drug
    qty { rand(100) }
    operation { InventoryEvent::VALID_OPERATIONS.sample }
  end
end

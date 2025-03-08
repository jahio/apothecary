class Drug < ApplicationRecord
  validates :name, :form, :administration_route, :description, :dea_identifier, :schedule, :dosage_unit, :dosage_qty, presence: true
end

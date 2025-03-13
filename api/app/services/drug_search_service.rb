class DrugSearchService
  attr_accessor :patient_state, :drug_name, :dosage_unit, :dosage_qty, :drug_form

  # These are the only ones built so far, it's easy to add more
  SEARCHABLE_VIEWS = [
    InventoriesMd, InventoriesTx, InventoriesVa
  ].freeze

  def initialize(patient_state:, drug_name:, dosage_unit:, dosage_qty:, drug_form:)
    @patient_state = patient_state
    @drug_name     = drug_name
    @dosage_unit   = dosage_unit
    @dosage_qty    = dosage_qty
    @drug_form     = drug_form
  end

  def search
    #
    # Based on the patient state, figure out which materialized view to
    # use for the search.
    #
    # TODO: Something more clever than this hacktastic stupidity
    klass = SEARCHABLE_VIEWS.select { |v| v.name[-2..-1].downcase == @patient_state.downcase }.first
    klass.where('LOWER(drug_name) LIKE LOWER(?)', "%#{@drug_name}%")
      .where(dosage_unit: @dosage_unit)
      .where(dosage_qty:  @dosage_qty)
  end

end

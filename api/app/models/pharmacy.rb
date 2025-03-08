class Pharmacy < ApplicationRecord

  has_many :inventories
  has_many :drugs, through: :inventories

  validates :name, :address, :city, :state, :zip, presence: true
  validate :must_have_one_phone
  validate :must_have_one_human

  before_save :strip_number_formatting

  private

  def strip_number_formatting
    [phones_human, phones_fax].each do |phone|
      phone.each do |p|
        p = p.gsub(/\D/, '')
      end
    end
  end

  def must_have_one_phone
    err_str = "You must enter at least one phone number for reaching a human; the standard pharmacy store number will suffice."

    if phones_human.count < 1
      errors.add(:phones_human, err_str)
      return
    end

    phones_human.each do |p|
      if p.gsub(/\D/, '').length < 10 # Standard for US numbers
        errors.add(:phones_human, "The phone number #{p} doesn't look quite right - please fix that and try again. Must be at least 10 digits regardless of formatting.")
        return
      end
    end
  end

  def must_have_one_human
    # TODO: Pharmacy#must_have_one_human - ensure the personnel JSONB hash has at least one person in it
  end
end

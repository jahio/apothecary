require "test_helper"

describe Inventory do
  subject { build(:inventory) }

  it "is valid on instantiation" do
    value(subject.valid?).must_equal true
  end

  it "has an associated pharmacy" do
    value(subject.pharmacy.blank?).must_equal false
  end

  it "has an associated drug" do
    value(subject.drug.blank?).must_equal false
  end
end

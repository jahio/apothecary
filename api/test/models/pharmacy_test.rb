require "test_helper"

describe Pharmacy do
  subject { build(:pharmacy) }

  it "is valid upon factory creation" do
    value(subject.valid?).must_equal true
  end
end

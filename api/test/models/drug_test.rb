require "test_helper"

describe Drug do
  subject { build(:drug) }

  it "is valid upon factory instantiation" do
    value(subject.valid?).must_equal true
  end
end

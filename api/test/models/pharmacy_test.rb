require "test_helper"

describe Pharmacy do
  subject { build(:pharmacy) }

  it "is valid upon factory creation" do
    value(subject.valid?).must_equal true
  end
  # it "does a thing" do
  #   value(1+1).must_equal 2
  # end
end

=begin

describe User do
  subject { User.new }

  # Works with shoulda-matchers
  it "should have fields and associations" do
    must have_db_column :name
    must belong_to :account
    must have_many :widgets
  end

  # Works with valid_attribute
  it "should validate" do
    must have_valid(:email).when("a@a.com", "foo@bar.com", "dave@abc.io")
    wont have_valid(:email).when(nil, "foo", "foo@bar", "@bar.com")
  end

  # Works with matchers in other libs
  it "should strip attributes" do
    must strip_attribute :name
  end
end

=end

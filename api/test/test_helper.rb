ENV["RAILS_ENV"] ||= "test"
# Consider setting MT_NO_EXPECTATIONS to not add expectations to Object.
# ENV["MT_NO_EXPECTATIONS"] = "true"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/rails"

module ActiveSupport
  class TestCase
    # Include all the FactoryBot methods:
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all

    # Set Faker's locale to US; this is so it doesn't generate strange formatted phone numbers etc.
    Faker::Config.locale = 'en-US'
  end
end

FactoryBot.define do
  factory :pharmacy do
    name { Faker::Company.name }
    address { Faker::Address.street_address }
    city { Faker::Address.city }
    state { Faker::Address.state_abbr }
    zip { Faker::Address.zip_code }
    phones_human { Array.new(3) { Faker::PhoneNumber.phone_number } }
    phones_fax { Array.new(3) { Faker::PhoneNumber.phone_number } }
    personnel {
      [
        {
          name: Faker::FunnyName.name,
          title: Faker::Job.title,
          phone: Faker::PhoneNumber.phone_number
        }
      ]
    }
  end
end

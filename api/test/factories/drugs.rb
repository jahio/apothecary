FactoryBot.define do
  factory :drug do
    name { SecureRandom.hex(6) }
    form { %w[liquid syrup tincture mist gas pill capsule tablet other].sample }
    administration_route { %w[oral injected inhaled].sample }
    description { Faker::Lorem.paragraph }
    dea_identifier { SecureRandom.uuid_v7 }
    schedule { (1..4).to_a.sample }
    dosage_unit { %w[mg ml mcg grains other].sample }
    dosage_qty { rand(1000) }
  end
end

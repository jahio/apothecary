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
    opioid { false }
    stimulant { false }
    depressant { false }
    addictive { false }
    painkiller { false }

    factory :test_cyp do
      name { "Testosterone Cypionate" }
      form { "injection" }
      administration_route { "intramuscular injection" }
      dosage_unit { "mg/ml" } # Dosed in X mg per ML of injected fluid
      schedule { 3 } # Not sure about this honestly

      # While not addictive, bodybuilders have been known to abuse testoserone
      # cypionate (and any form of external testosterone supplementation) for
      # rapid post-workout recovery. What they don't pay attention to is the
      # fact that too much can thicken the viscosity of your blood, forcing
      # your heart to work so hard to keep it flowing that at some point, it
      # could just...stop.
      addictive { false }

      factory :test_cyp_100 do
        dosage_qty { 100 }
      end

      factory :test_cyp_200 do
        dosage_qty { 200 }
      end
    end

    factory :cough_syrup do
      name { "Codeine/Guafenisin Cough Syrup" }
      form { "liquid" }
      administration_route { "oral" }
      dosage_unit { "mg/mg/mL" }
      schedule { 3 }

      # All of these are due to the codeine
      addictive { true }
      painkiller { true }
      opioid { true }
      depressant { true }

      # This is for a mix of codeine/guafenisin cough syrup often
      # prescribed for folks with severe coughing issues. The 10 here
      # denotes 10mg of codeiene per dosing unit (100mg of guafenisin
      # per same unit, hypothetically)
      factory :cough_syrup_10_100 do
        dosage_qty { 10 }
      end
    end

    factory :fentanyl do
      name { "Fentanyl" }
      form { "patch" }
      administration_route { "transdermal" }
      dosage_unit { "mcg" }
      schedule { 2 }
      addictive { true }
      opioid { true }
      depressant { true }
      painkiller { true }

      # I'm pulling these numbers out of thin air; this is
      # likely not factual.
      factory :fentanyl_125 do
        dosage_qty { 125 }
      end

      factory :fentanyl_200 do
        dosage_qty { 200 }
      end
    end

    factory :modafinil do
      name { "Modafinil" }
      form { "tablet" }
      administration_route { "oral" }
      dosage_unit { "mg" }
      schedule { 2 }
      addictive { true }
      stimulant { true }

      factory :modafinil_100 do
        dosage_qty { 100 }
      end

      factory :modafinil_200 do
        dosage_qty { 200 }
      end
    end

    factory :vyvanse do
      name { "Vyvanse" }
      form { "capsule" }
      administration_route { "oral" }
      dosage_unit { "mg" }
      schedule { 2 }
      addictive { true }
      stimulant { true }

      factory :vyvanse_80 do
        dosage_qty { 80 }
      end

      factory :vyvanse_100 do
        dosage_qty { 100 }
      end
    end

    factory :topamax do
      name { "Topamax (Topiramate)" }
      form { "tablet" }
      administration_route { "oral" }
      dosage_unit { "mg" }
      schedule { 4 }

      factory :topamax_50 do
        dosage_qty { 50 }
      end

      factory :topamax_100 do
        dosage_qty { 100 }
      end

      factory :topamax_150 do
        dosage_qty { 150 }
      end
    end

    factory :propranolol do
      name { "Propranalol" }
      form { "tablet" }
      administration_route { "oral" }
      dosage_unit { "mg" }
      schedule { 4 }

      factory :propranolol_10 do
        dosage_qty { 10 }
      end

      factory :propranolol_20 do
        dosage_qty { 20 }
      end

      factory :propranolol_40 do
        dosage_qty { 40 }
      end

      factory :propranolol_80 do
        dosage_qty { 80 }
      end
    end
  end
end

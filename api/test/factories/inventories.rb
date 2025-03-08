FactoryBot.define do
  factory :inventory do
    drug
    pharmacy

    #
    # The rand() method behaves rather strangely, so there are some
    # additional safeguards below where it's used to prevent odd,
    # drastically unrealistic scenarios from coming about.
    #
    physical_qty { rand(1000) + 1000 }
    qty_reserved { physical_qty - rand(777) }

    # This one's very weird: Testing revealed everything from division by zero
    # to literal Infinity even though it was just 100.0 divided by 10.0 initially.
    price_per_unit { (rand(100.0) + 0.9) / (rand(10) + 1.0) }
  end
end

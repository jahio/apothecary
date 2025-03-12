require 'etc'

# Total number of threads we'll use for seeding
n_threads = Etc.nprocessors

# Total number of pharmacies and drugs across all threads
t_pharmacies = 1_000
t_drugs = 1_000

# Purge the relevant tables
[Inventory, Drug, Pharmacy].each { |k| k.send(:delete_all) }

# Create some real-world drugs based on the factories from the tests
[
  :propranolol_10, :propranolol_20, :propranolol_40, :propranolol_80,
  :topamax_50, :topamax_100, :topamax_150,
  :vyvanse_100, :vyvanse_80,
  :modafinil_100, :modafinil_200,
  :fentanyl_125, :fentanyl_200,
  :cough_syrup_10_100,
  :test_cyp_100, :test_cyp_200
].each { |d| FactoryBot.create(d) }

#
# Large-scale seeds
#
generation_threads = Array.new(n_threads) do
  Thread.new do
    # Here we define the work to be done in each thread
    # Note that nothing actually happens until we call Thread#join below
    # Start by defining the total number of items to be iterated on per thread
    # so we don't go overboard
    n_pharmacies = (t_pharmacies / n_threads).round
    n_drugs = (t_drugs / n_threads).round

    # Generate N of each model
    FactoryBot.create_list(:drug, n_drugs)
    FactoryBot.create_list(:pharmacy, n_pharmacies)
  end
end

generation_threads.map(&:join)

# Next, we need to stripe all the pharmacies across the whole of a thread pool basically
# so we can spread the load of creating inventories across the entirety of our hardware
total_pharmacies = Pharmacy.count
pharmacies_per_thread = (total_pharmacies.to_f / n_threads).ceil
inventory_threads = n_threads.times.map do |i|
  Thread.new do
    offset = i * pharmacies_per_thread
    limit = [pharmacies_per_thread, total_pharmacies - offset].min
    next if limit <= 0

    Pharmacy.offset(offset).limit(limit).each do |p|
      Drug.all.each do |d|
        x = FactoryBot.build(:inventory, pharmacy: p, drug: d)
        # For reasons unknown, the price isn't getting rounded in all cases; force it here
        x.price_per_unit = x.price_per_unit.round(2)
        x.save
      end
    end
  end
end

inventory_threads.each(&:join)

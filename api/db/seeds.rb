# Purge the relevant tables
[Inventory, Drug, Pharmacy].each { |k| k.send(:delete_all) }

# Create some drugs based on the factories from the tests
propranolol = [:propranolol_10, :propranolol_20, :propranolol_40, :propranolol_80]
topamax = [:topamax_50, :topamax_100, :topamax_150]
vyvanse = [:vyvanse_100, :vyvanse_80]
modafinil = [:modafinil_100, :modafinil_200]
fentanyl = [:fentanyl_125, :fentanyl_200]
cough_syrup = [:cough_syrup_10_100]
test_cyp = [:test_cyp_100, :test_cyp_200]

drugs = [propranolol, topamax, modafinil, fentanyl, vyvanse, cough_syrup, test_cyp]

drugs.each { |d| d.each { |x| FactoryBot.create(x) } }

# Create some pharmacies based on factories - in an ideal scenario we'd load this from
# data provided in the real world, e.g. a CSV of real and existing locations; for now we'll
# just have to settle for fake stuff.
pharmacies = FactoryBot.create_list(:pharmacy, 15)

# For each pharmacy, we're going to generate some fake inventory based on our list
# of very real drugs outlined above.
pharmacies.each do |p|
  Drug.all.each do |d|
    i = FactoryBot.build(:inventory, pharmacy: p, drug: d)
    # For reasons unknown, the price isn't getting rounded in all cases; force it here
    i.price_per_unit = i.price_per_unit.round(2)
    i.save
  end
end

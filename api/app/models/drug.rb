class Drug < ApplicationRecord
  validates :name, :form, :administration_route, :description, :dea_identifier, :schedule, :dosage_unit, :dosage_qty, presence: true

  has_many :inventories
  has_many :pharmacies, through: :inventories
end


=begin

ActiveRecord::Base.logger = Logger.new(STDOUT)
p = Pharmacy.where(state: "TX")
d = Drug.first
Inventory.where('physical_qty - qty_reserved > 0').where(pharmacy: p, drug: d).explain(:analyze)

=>
EXPLAIN (ANALYZE) SELECT "inventories".* FROM "inventories" WHERE (physical_qty - qty_reserved > 0) AND "inventories"."pharmacy_id" IN (SELECT "pharmacies"."id" F>
                                                                         QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=51.67..979.44 rows=7 width=88) (actual time=0.486..6.547 rows=22 loops=1)
   ->  Bitmap Heap Scan on pharmacies  (cost=8.42..81.20 rows=19 width=16) (actual time=0.025..0.058 rows=19 loops=1)
         Recheck Cond: (state = 'TX'::text)
         Heap Blocks: exact=17
         ->  Bitmap Index Scan on index_pharmacies_on_state  (cost=0.00..8.42 rows=19 width=0) (actual time=0.015..0.016 rows=19 loops=1)
               Index Cond: (state = 'TX'::text)
   ->  Bitmap Heap Scan on inventories  (cost=43.25..47.27 rows=1 width=88) (actual time=0.337..0.337 rows=1 loops=19)
         Recheck Cond: ((drug_id = '01958840-6a1e-7e18-81e9-090ef3611baf'::uuid) AND (pharmacy_id = pharmacies.id))
         Filter: ((physical_qty - qty_reserved) > 0)
         Heap Blocks: exact=22
         ->  BitmapAnd  (cost=43.25..43.25 rows=1 width=0) (actual time=0.326..0.326 rows=0 loops=19)
               ->  Bitmap Index Scan on index_inventories_on_drug_id  (cost=0.00..20.33 rows=1054 width=0) (actual time=0.190..0.190 rows=996 loops=19)
                     Index Cond: (drug_id = '01958840-6a1e-7e18-81e9-090ef3611baf'::uuid)
               ->  Bitmap Index Scan on index_inventories_on_pharmacy_id  (cost=0.00..22.57 rows=1353 width=0) (actual time=0.063..0.063 rows=1172 loops=19)
                     Index Cond: (pharmacy_id = pharmacies.id)
 Planning Time: 0.705 ms
 Execution Time: 6.622 ms
(17 rows)

=end

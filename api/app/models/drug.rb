class Drug < ApplicationRecord
  validates :name, :form, :administration_route, :description, :dea_identifier, :schedule, :dosage_unit, :dosage_qty, presence: true

  has_many :inventories
  has_many :pharmacies, through: :inventories
end


=begin

                                                           QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------
 Hash Join  (cost=14.87..30.08 rows=15 width=241) (actual time=0.165..0.317 rows=15 loops=1)
   Hash Cond: (inventories.pharmacy_id = pharmacies.id)
   ->  Nested Loop  (cost=0.15..15.32 rows=15 width=257) (actual time=0.060..0.203 rows=15 loops=1)
         ->  Index Scan using drugs_pkey on drugs  (cost=0.15..8.17 rows=1 width=241) (actual time=0.034..0.037 rows=1 loops=1)
               Index Cond: (id = '019583b6-9aa6-7535-aafc-df69be985f43'::uuid)
         ->  Seq Scan on inventories  (cost=0.00..7.00 rows=15 width=32) (actual time=0.021..0.157 rows=15 loops=1)
               Filter: (drug_id = '019583b6-9aa6-7535-aafc-df69be985f43'::uuid)
               Rows Removed by Filter: 225
   ->  Hash  (cost=12.10..12.10 rows=210 width=16) (actual time=0.025..0.025 rows=15 loops=1)
         Buckets: 1024  Batches: 1  Memory Usage: 9kB
         ->  Seq Scan on pharmacies  (cost=0.00..12.10 rows=210 width=16) (actual time=0.012..0.014 rows=15 loops=1)
 Planning Time: 0.787 ms
 Execution Time: 0.396 ms
(13 rows)

---

Explain/Analyze'd query:

EXPLAIN ANALYZE SELECT "drugs".* FROM "drugs" INNER JOIN "inventories" ON "inventories"."drug_id" = "drugs"."id" INNER JOIN "pharmacies" ON "pharmacies"."id" = "inventories"."pharmacy_id" WHERE "drugs"."id" = '019583b6-9aa6-7535-aafc-df69be985f43';


Consider:
- Inner loop: 225 rows removed by filter, 0 to 7.0 cost, 15 rows returned
- Next up: 0.15 to 8.17 for just ONE ROW!
- Next out: 0.15 to 15.32 for 15 rows, 0.6 to 0.203! From 7.0 to 203! That's 29 times larger in size, exactly! (203/7 = 29)
- Final up: 14.87 to 30.08, 15 rows, 0.165 to 0.317 for merely 15 rows, one loop
- And that's WITH indexes - and a lot of stuff we get handed from previous contractors hasn't got ANY indexes at all!

=end

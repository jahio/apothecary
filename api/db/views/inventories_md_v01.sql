SELECT
  gen_random_uuid() AS id,
  drugs.id AS drug_id,
  inventories.drug_id AS inv_drug_id,
  inventories.pharmacy_id AS inv_pharmacy_id,
  drugs.name AS drug_name,
  drugs.form AS drug_form,
  drugs.administration_route,
  drugs.dosage_unit,
  drugs.dosage_qty,
  pharmacies.id AS pharmacy_id,
  pharmacies.name AS pharmacy_name,
  pharmacies.address AS pharmacy_address,
  pharmacies.city AS pharmacy_city,
  pharmacies.state AS pharmacy_state,
  pharmacies.zip AS pharmacy_zip,
  SUM(inventories.physical_qty - inventories.qty_reserved) AS available_qty
  NOW() as created_at,
  NOW() as updated_at
FROM drugs, pharmacies, inventories
WHERE drugs.id = inventories.drug_id
AND pharmacies.id = inventories.pharmacy_id
AND pharmacies.state = 'MD' -- Change this for each state
GROUP BY
  drugs.id,
  inventories.drug_id,
  inventories.pharmacy_id,
  pharmacies.id,
  pharmacies.state
ORDER BY
  available_qty DESC;

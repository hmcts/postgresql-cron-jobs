-- claimant_Company
 UPDATE case_data SET data = jsonb_set(data,'{claimant_Company}', to_jsonb(translate(data #>>'{claimant_Company}','AEabemcofghjk134','xyz')), FALSE) WHERE data #>>'{claimant_Company}' IS NOT NULL;
 
 --SELECT reference, translate(data #>>'{claimant_Company}','Aabecofghjk134','xmz') AS fake, data->>'claimant_Company' as claimant_Company FROM case_data where data->>'claimant_Company' IS NOT NULL ORDER BY id DESC LIMIT 5;
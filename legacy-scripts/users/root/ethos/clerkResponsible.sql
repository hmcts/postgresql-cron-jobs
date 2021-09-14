-- clerkResponsible

--SELECT reference, data->>'clerkResponsible' AS fake, data->>'clerkResponsible' as clerkResponsible FROM case_data WHERE reference = 1603380700581114;
-- select translate(data #>>'{clerkResponsible}','abcofghjk134P','Xzyx') AS fake,  data->>'clerkResponsible' AS ORIG FROM case_data where data->>'clerkResponsible' IS NOT NULL limit 505;
 
  UPDATE case_data SET data = jsonb_set(data,'{clerkResponsible}', to_jsonb(translate(data #>>'{clerkResponsible}','abcofghjk134P','Xzyx')), FALSE) WHERE data #>>'{clerkResponsible}' IS NOT NULL;
  
  
 
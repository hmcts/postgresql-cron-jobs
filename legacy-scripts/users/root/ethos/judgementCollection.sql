-- judgementCollection
-- select id, translate(data #>>'{judgementCollection}','abcofghejk135','zyx') AS fake,  data->>'judgementCollection'  FROM case_data where data->>'judgementCollection' IS NOT NULL limit 5;

 UPDATE case_data SET data = jsonb_set(data,'{judgementCollection}', to_jsonb(translate(data #>>'{judgementCollection}','abcofghejk135','zyx')), FALSE) WHERE data #>>'{judgementCollection}' IS NOT NULL;
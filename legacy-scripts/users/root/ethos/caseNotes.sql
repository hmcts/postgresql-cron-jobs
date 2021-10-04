-- caseNotes
-- select id, translate(data #>>'{caseNotes}','abcofghjk12345','zyx') AS fake,  data->>'caseNotes'  FROM case_data where data->>'caseNotes' IS NOT NULL limit 5;

 UPDATE case_data SET data = jsonb_set(data,'{caseNotes}', to_jsonb(translate(data #>>'{caseNotes}','Aabcofghjk12345','xyz')), FALSE) WHERE data #>>'{caseNotes}' IS NOT NULL;
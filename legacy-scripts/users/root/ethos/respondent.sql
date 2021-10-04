-- respondent

UPDATE case_data SET data = jsonb_set(data, '{respondent}', to_jsonb(translate(data #>>'{respondent}', 'Abcoefghijk123','zyx')), FALSE) WHERE data #>>'{respondent}' IS NOT NULL; 

 --SELECT translate(data #>>'{respondent}', 'abcoefghijk123','zyx') AS fake, data #>>'{respondent}' AS original  from case_data where data->>'respondent' IS NOT NULL limit 5;

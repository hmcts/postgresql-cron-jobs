-- restrictedReporting
UPDATE case_data SET data = jsonb_set(data, '{restrictedReporting,excludedNames}', to_jsonb(translate(data #>>'{restrictedReporting,excludedNames}', 'adefohin123','xjz')), FALSE) WHERE data #>>'{restrictedReporting,excludedNames}' IS NOT NULL; 

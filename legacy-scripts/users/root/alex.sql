with rows as (
SELECT 
   cd.reference,  
   ce.id,
   ce.case_data_id,
   ce.event_id,
   UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'identity'->>'nino', ' ', '', 'g')) AS nino,
   lag(UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'identity'->>'nino', ' ', '', 'g'))) over w as prev_nino,
   UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'name'->>'lastName', ' ', '', 'g')) AS surname,
   lag(UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'name'->>'lastName', ' ', '', 'g'))) over w as prev_surname
FROM
   case_event ce JOIN case_data cd ON ce.case_data_id=cd.id
   where jurisdiction = 'SSCS'
   window w as (partition by case_data_id order by ce.id asc)
)
select id, case_data_id from rows
WHERE event_id = 'actionFurtherEvidence' 
and (nino <> prev_nino
  or surname <> prev_surname);

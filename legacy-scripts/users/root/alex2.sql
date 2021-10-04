\copy (with rows as (
SELECT
   ce.id,
   ce.case_data_id,
   ce.event_id,
   UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'identity'->>'nino', ' ', '', 'g')) AS nino,
   lag(UPPER(regexp_replace(ce.data->'appeal'->'appellant'->'identity'->>'nino', ' ', '', 'g'))) over w as prev_nino
FROM
   case_event ce 
   where case_type_id = 'Benefit'
   window w as (partition by case_data_id order by ce.id asc)
)
select
*
from rows
WHERE prev_nino is not null and nino <> prev_nino) to '/tmp/alex2.csv' with csv header;

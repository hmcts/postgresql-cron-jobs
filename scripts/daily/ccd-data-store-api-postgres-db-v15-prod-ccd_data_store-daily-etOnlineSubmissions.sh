#!/bin/bash
cat <<EOF
COPY (
select data->>'managingOffice' as managingOffice,
       case
           when case_event.event_id = 'SUBMIT_CASE_DRAFT' then 'ET1 Online'
           when case_event.event_id = 'submitEt1Draft' then 'MyHMCTS ET1'
           when case_event.event_id = 'submitEt3' then 'MyHMCTS ET3'
           else event_id
       end as submissionSource,
       count(*) filter (where created_date > now() - interval '24 hours') as last_24_hours,
       count(*) filter (where created_date > now() - interval '1 week') as last_week,
       count(*) filter (where created_date > now() - interval '1 month') as last_month,
       count(*) as totalSubmissions
from case_event
where event_id in ('submitEt1Draft', 'SUBMIT_CASE_DRAFT', 'submitEt3')
  and case_event.case_type_id in ('ET_EnglandWales', 'ET_Scotland')
group by event_id, submissionSource, managingOffice) to stdout with csv header;
EOF
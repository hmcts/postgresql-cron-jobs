#!/bin/bash
cat <<EOF
COPY (
select case
when case_event.case_type_id = 'ET_EnglandWales' then data ->> 'managingOffice'
else 'Scotland'
end as managingOffice,
case
when case_event.event_id = 'SUBMIT_CASE_DRAFT' then 'ET1 Online'
when case_event.event_id = 'submitEt1Draft' then 'MyHMCTS ET1'
when case_event.event_id = 'submitEt3' then 'MyHMCTS ET3'
else event_id
end as submissionSource,
count(*) as totalNoOfCases,
count(*) filter (where created_date >= now() - interval '7 days')  as "0-7 days ago",
count(*) filter (where created_date >= now() - interval '14 days' and created_date <= now() - interval '7 days')  as "7-14 days ago",
count(*) filter (where created_date >= now() - interval '21 days' and created_date <= now() - interval '14 days') as "14-21 days ago",
count(*) filter (where created_date >= now() - interval '28 days' and created_date <= now() - interval '21 days') as "21-28 days ago",
from case_event
where event_id in ('submitEt1Draft', 'SUBMIT_CASE_DRAFT', 'submitEt3')
and case_event.case_type_id in ('ET_EnglandWales', 'ET_Scotland')
group by event_id, submissionSource, managingOffice)
to stdout with csv header;
EOF
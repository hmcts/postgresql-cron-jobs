#!/bin/bash
cat <<EOF
COPY (
select case_event.case_type_id, count(distinct(case_data.id)) as cases, count(case_event.id) as case_events
from case_data join case_event on case_data.id = case_event.case_data_id
where case_data.jurisdiction = 'EMPLOYMENT'
group by 1 order by 1) TO STDOUT WITH CSV HEADER ;
EOF
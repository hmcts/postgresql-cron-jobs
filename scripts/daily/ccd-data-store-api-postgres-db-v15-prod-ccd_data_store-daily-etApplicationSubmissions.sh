#!/bin/bash
cat <<EOF
COPY (
select data ->> 'managingOffice'     as Office,
       reference::text,
       data ->> 'ethosCaseReference' as ethosRef,
       application.application_type,
       application.application_date,
       application.applicant
from case_data
         cross join lateral (
    select applications -> 'value' ->> 'type'                           as application_type,
           TO_DATE(applications -> 'value' ->> 'date', 'DD Month YYYY') as application_date,
           applications -> 'value' ->> 'applicant'                      as applicant
    from jsonb_array_elements(case_data.data -> 'genericTseApplicationCollection') as applications
    ) as application
where case_type_id in ('ET_EnglandWales', 'ET_Scotland')
  and data -> 'genericTseApplicationCollection' is not null
order by application.application_date desc) to stdout with csv header;
EOF
#!/bin/bash
DAYSAGO=$(date -d "8 days ago" '+%Y%m%d 00:00:00')
cat <<EOF
COPY (
SELECT to_char(CAST (ce.created_date AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
 trim(ce.data->>'registryLocation') AS registry,
 cd.reference AS case_number,
 ce.data ->> 'deceasedSurname' AS Deceased_Surname,
 ce.data ->> 'deceasedForenames' AS Deceased_Forename,
 jsonb_array_elements(ce.data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason
 FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE ce.case_type_id = 'GrantOfRepresentation' AND ce.event_id='boFailQA' AND ce.data->>'registryLocation' = 'ctsc'
AND ce.data #>> '{boCaseStopReasonList}' IS NOT NULL
--AND ce.created_date::date between '20200113' and '20200119'  ORDER BY 4 ) to stdout with csv header
AND ce.created_date::date >= '${DAYSAGO}'  ORDER BY 4 ) to stdout with csv header
EOF
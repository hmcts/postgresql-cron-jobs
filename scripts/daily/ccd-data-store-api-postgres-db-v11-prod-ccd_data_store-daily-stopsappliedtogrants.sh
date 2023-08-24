#!/bin/bash
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
cat <<EOF
COPY (
SELECT to_char(CAST (cd.data ->> 'grantStoppedDate' AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
trim(cd.data->>'registryLocation') AS registry,
cd.reference AS case_number,
CONCAT(cd.data ->> 'deceasedSurname', ' ',cd.data ->> 'deceasedForenames') AS full_name,
jsonb_array_elements(cd.data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason,
ce.user_first_name || ' ' || ce.user_last_name as author
FROM case_data as cd , case_event as ce
WHERE cd.jurisdiction = 'PROBATE' AND cd.state='BOCaseStopped'
AND cd.id = ce.case_data_id
AND cd.data #>> '{boCaseStopReasonList}' IS NOT NULL
AND CAST (cd.data ->> 'grantStoppedDate' AS DATE) = '${YESTERDAY}'
AND ce.created_date::date = '${YESTERDAY}'
AND ce.event_id = 'boStopCase' ORDER BY 3) to stdout with csv header;
EOF

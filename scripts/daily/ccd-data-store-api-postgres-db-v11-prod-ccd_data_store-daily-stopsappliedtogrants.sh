#!/bin/bash
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
cat <<EOF
COPY (
SELECT to_char(CAST (last_modified AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
 trim(data->>'registryLocation') AS registry,
 reference AS case_number,
 CONCAT(data ->> 'deceasedSurname', ' ',data ->> 'deceasedForenames') AS full_name,
 jsonb_array_elements(data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason
 FROM case_data
 WHERE jurisdiction = 'PROBATE' AND state='BOCaseStopped'
AND data #>> '{boCaseStopReasonList}' IS NOT NULL
AND last_modified::date = '${YESTERDAY}'  ORDER BY 3 ) to stdout with csv header;
--AND last_modified::date between '20190326' and '20190520'  ORDER BY 3 ) to stdout with csv header;
EOF

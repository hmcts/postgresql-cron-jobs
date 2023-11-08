#!/bin/bash
YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d')
cat <<EOF
COPY (
SELECT
cd.reference AS ccd_reference,
to_char(CAST (cd.data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY') AS grant_issued_date, (now() AS created_date ),
trim(cd.data->>'deceasedForenames') AS deceasedForenames,
trim(cd.data->>'deceasedSurname') AS deceasedSurname,
trim(cd.data->>'registryLocation') AS registryLocation,
ce.user_first_name || ' ' || ce.user_last_name as author
FROM case_data as cd , case_event as ce
WHERE cd.id = ce.case_data_id
AND cd.jurisdiction = 'PROBATE'
AND ce.event_id ='boIssueGrantForCaseMatching'
AND (cd.data->>'grantIssuedDate') = '$YESTERDAY'
AND ce.created_date::date = '$YESTERDAY' ) to stdout with csv header;
EOF

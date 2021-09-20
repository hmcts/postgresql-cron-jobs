#!/bin/bash
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
cat <<EOF
COPY (
SELECT
reference AS ccd_reference,
to_char(CAST (data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY') AS grant_issued_date,
trim(data->>'deceasedForenames') AS deceasedForenames,
trim(data->>'deceasedSurname') AS deceasedSurname,
trim(data->>'registryLocation') AS registryLocation
FROM case_data
WHERE jurisdiction='PROBATE' AND (data->>'grantIssuedDate')::date = '$YESTERDAY' ORDER BY 4) to stdout with csv header;
EOF

#!/bin/bash
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
cat <<EOF
COPY (
 SELECT reference, state, to_char(CAST (data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY')  AS grant_issued_date, data->>'paperForm' AS paperForm, data->>'applicationType' AS  applicationType,created_date, last_modified   FROM case_data  WHERE jurisdiction = 'PROBATE' AND  data->>'languagePreferenceWelsh' = 'Yes' AND created_date::date >= '$YESTERDAY' order by created_date) TO STDOUT with csv header ;
EOF
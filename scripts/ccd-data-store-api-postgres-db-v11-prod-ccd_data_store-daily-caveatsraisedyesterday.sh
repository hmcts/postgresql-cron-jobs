#!/bin/bash
cat <<EOF
COPY (SELECT cd.reference AS ccd_reference,
ce.created_date AS caveat_raised_date_time,
CASE WHEN cd.data->>'registryLocation' IS NULL THEN 'NULL'  ELSE trim(cd.data->>'registryLocation')  END AS registryLocation,
CASE WHEN cd.data->>'paperForm' IS NULL THEN 'NULL'  ELSE trim(cd.data->>'paperForm')  END AS paperForm
FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id
--WHERE cd.jurisdiction='PROBATE' AND ce.state_id='CaveatRaised' AND ce.created_date::date between '20200118' and '20200119'
WHERE cd.jurisdiction='PROBATE' AND ce.state_id='CaveatRaised' AND ce.created_date::date = '$YESTERDAY'
ORDER BY 1,2) TO STDOUT WITH CSV HEADER ;
EOF
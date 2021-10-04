#!/bin/bash
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
cat <<EOF
COPY (
 SELECT reference, created_date, state, data->>'pcqId' AS PCQ_id, data->>'paperForm' AS paperForm, data->>'applicationType' AS applicationType, case_type_id AS type FROM case_data WHERE jurisdiction = 'PROBATE' AND data->>'pcqId' IS NOT NULL AND created_date >= '${DAYSAGO}' ORDER BY 2) TO STDOUT with csv header ;
EOF
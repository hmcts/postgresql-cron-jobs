#!/bin/bash
cat <<EOF
COPY (
 SELECT reference, created_date, state, data->'appeal'->'benefitType'->>'code' AS benefitType, data->'pcqId' AS pcqId   FROM case_data WHERE case_type_id ='Benefit' AND jurisdiction = 'SSCS' AND data->> 'pcqId' IS NOT NULL AND created_date >= '${DAYSAGO}' ORDER BY 2) TO STDOUT with csv header ;
EOF
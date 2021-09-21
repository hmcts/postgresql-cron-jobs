cat <<EOF
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
COPY (
 SELECT reference, created_date, state, trim(jsonb_array_elements(data->'applicants')->'value'->>'pcqId')::varchar AS applicants_pcqId, trim(jsonb_array_elements(data->'respondents')->'value'->>'pcqId')::varchar AS respondents_pcqId  FROM case_data WHERE case_type_id ='MoneyClaimCase' AND jurisdiction = 'CMC' AND (data -> 'applicants' -> 0 -> 'value' ->> 'pcqId' IS NOT NULL OR data -> 'respondents' -> 0 -> 'value' ->> 'pcqId' IS NOT NULL) AND created_date >= '${DAYSAGO}' ORDER BY 2) TO STDOUT with csv header ;
EOF
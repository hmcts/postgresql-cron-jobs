cat <<EOF
COPY (SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id AS ce_id,
CE.case_data_id AS ce_case_data_id,
CE.created_date AS ce_created_date,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
trim(CE.event_id) AS ce_event_id,
trim(CE.event_name) AS ce_event_name,
trim(CE.state_id) AS ce_state_id,
trim(CE.state_name) AS ce_state_name,
CD.created_date AS cd_created_date,
CD.last_modified AS cd_last_modified,
trim(CD.jurisdiction) AS cd_jurisdiction,
CD.reference AS cd_reference,
trim(CE.user_id)       AS ce_user_id,
trim(CE.user_first_name) AS ce_user_first_name,
trim(CE.user_last_name)  AS ce_user_last_name
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id
AND CE.created_date >= (current_date-8 + time '00:00')
AND CE.created_date < (current_date+1 + time '00:00')
ORDER BY CE.created_date ASC) TO STDOUT WITH CSV HEADER
EOF

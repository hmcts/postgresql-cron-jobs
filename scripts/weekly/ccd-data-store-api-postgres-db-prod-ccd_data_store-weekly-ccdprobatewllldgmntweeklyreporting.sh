#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id			AS case_metadata_event_id,
CE.case_data_id		AS ce_case_data_id,
CE.created_date		AS ce_created_date,
trim(CE.case_type_id)	AS ce_case_type_id,
CE.case_type_version	AS ce_case_type_version,
trim(CE.data ->>'applicationType') AS ce_app_type,
trim(CE.data ->>'registryLocation') AS ce_reg_location,
trim(CE.data ->>'lodgementType') AS ce_lodgement_type,
trim(CE.data ->>'lodgedDate') AS ce_lodgement_date,
trim(CE.data ->>'withdrawalReason') AS ce_withdrawal_reason,
trim(CE.data ->>'legacyId') AS ce_leg_record_id
FROM case_event CE
WHERE CE.case_type_id = 'WillLodgement'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER ;
EOF
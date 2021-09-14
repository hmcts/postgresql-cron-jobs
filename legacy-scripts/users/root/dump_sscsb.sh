#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Default to yesterday so we get a full days reconciliation
  DEFAULT_DATE=$(date +%F) ##--date '-1 days')

  #OUTPUT_DIR=/mnt/c/Users/user/Documents
  OUTPUT_DIR=/tmp
  OUTPUT_FILE_NAME=SSCS_${DEFAULT_DATE}.csv

  QUERY=$(cat <<EOF
COPY (
SELECT CURRENT_TIMESTAMP AS extraction_date,
trim(CD.jurisdiction) AS cd_service,
CE.created_date AS ce_created_date,
CD.created_date AS cd_org_created_date,
CD.last_modified AS cd_last_modified_date,
trim(CE.event_id) AS ce_event_id,
trim(CE.event_name) AS ce_event_name,
trim(CE.state_id) AS ce_state_id,
trim(CE.state_name) AS ce_state_name,
trim(CD.state) AS cd_state,
trim(CE.case_type_id) AS ce_case_type_id,
trim(CD.case_type_id) AS cd_case_type_id,
CE.case_type_version AS ce_case_type_version,
(CD.data->'subscriptions'->'appellantSubscription'->>'subscribeSms')::varchar AS cd_subscribe_sms, 
(CD.data->'subscriptions'->'appellantSubscription'->>'subscribeEmail')::varchar AS cd_subscribe_email, 
(CD.data->>'region')::varchar AS cd_region, 
(CD.data->'appeal'->'benefitType'->>'description')::varchar AS cd_benefit_type, 
(CD.data->'appeal'->'benefitType'->>'code')::varchar AS cd_benefit_code, 
(CD.data->'appeal'->>'hearingType')::varchar as cd_hearing_type, 
(jsonb_array_elements(CD.data->'hearings')->'value'->'venue'->>'name')::varchar as cd_venue_name 
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id 
AND CD.jurisdiction='SSCS'
AND CE.id IN (SELECT MAX(CE2.id) FROM case_event CE2 WHERE CE2.case_data_id=CE.case_data_id)
ORDER BY cd_last_modified_date ASC
) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "SSCS Dump Complete"

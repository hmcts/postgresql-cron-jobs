#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Default to yesterday so we get a full days reconciliation
  DEFAULT_DATE=$(date +%F) ##--date '-1 days')

  OUTPUT_DIR=/tmp
  OUTPUT_FILE_NAME=PROBATE_${DEFAULT_DATE}.csv

  QUERY=$(cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
trim(CD.jurisdiction) AS cd_service,
CD.reference AS ccd_reference,
CE.id AS ce_id,
CE.created_date AS ce_created_date,
CD.last_modified AS cd_last_modified_date,
CD.data->>'applicationSubmittedDate' AS applicationSubmittedDate,
trim(CE.event_id) AS ce_event_id,
trim(CE.event_name) AS ce_event_name,
trim(CE.state_id) AS ce_state_id,
trim(CE.state_name) AS ce_state_name,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
CD.data->>'applicationType' AS ApplicationType,
CD.data->>'numberOfExecutors' AS numberOfExecutors,
CD.data->>'numberOfApplicants' AS numberOfApplicants,
trim(jsonb_array_elements(CD.data->'boCaseStopReasonList')->'value'->>'caseStopReason')::varchar AS boCaseStopReasonList_caseStopReason,
CASE WHEN CD.data->>'registryLocation' IS NULL THEN 'OTHER'
ELSE CD.data->>'registryLocation' END AS cd_registry_location
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id
AND CD.jurisdiction='PROBATE' AND CD.created_date::date >= '20181201'
ORDER BY CE.case_data_id, CE.created_date) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccd@ccd-data-store-api-postgres-db-prod -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Probate Dump Complete"

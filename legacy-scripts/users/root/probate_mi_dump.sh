#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Default to yesterday so we get a full days reconciliation
  DEFAULT_DATE=$(date +%F) ##--date '-1 days')

  OUTPUT_DIR=/tmp
  OUTPUT_FILE_NAME=MI_PROBATE_${DEFAULT_DATE}.csv

  QUERY=$(cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
trim(CD.jurisdiction) AS cd_service,
trim(CE.state_id) AS stateid,
CD.data->>'applicationSubmittedDate' AS applicationSubmittedDate,
trim(jsonb_array_elements(CD.data->'boCaseStopReasonList')->'value'->>'caseStopReason')::varchar AS boCaseStopReasonList_caseStopReason,
CD.data->>'applicationType' AS ApplicationType,
'' AS CaveatClosed,
'' AS expiryDate,
CD.created_date AS applicationcreateddate,
CASE WHEN CD.data->>'registryLocation' IS NULL THEN 'OTHER' ELSE CD.data->>'registryLocation' END AS registry_location,
CD.last_modified AS cd_last_modified_date
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id
AND CD.jurisdiction='PROBATE' AND CD.created_date::date >= '20181101'
ORDER BY CE.case_data_id, CE.created_date) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Probate MI Dump Complete"

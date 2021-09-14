#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Default to yesterday so we get a full days reconciliation
  DEFAULT_DATE=$(date +%F) ##--date '-1 days')

  #OUTPUT_DIR=/mnt/c/Users/user/Documents/
  OUTPUT_DIR=/tmp/
  OUTPUT_FILE_NAME=DIVORCE_${DEFAULT_DATE}.csv

  QUERY=$(cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
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
CASE WHEN trim(CD.data->>'D8DivorceUnit') IS NULL THEN 'OTHER'
ELSE trim(CD.data->>'D8DivorceUnit') END AS cd_divorce_unit,
trim(CD.data ->>'D8PetitionerContactDetailsConfidential') AS cd_contact_confidential,
trim(CD.data ->> 'D8HelpWithFeesNeedHelp') AS cd_need_help_with_fees,
trim(CD.data ->> 'D8FinancialOrder') AS cd_financial_order,
trim(CD.data ->> 'D8ReasonForDivorce') AS cd_reason_for_divorce,
trim(CD.data ->> 'D8DivorceClaimFrom') AS cd_divorce_claim_from,
trim(CD.data ->>'D8ReasonForDivorceAdulteryWishToName') as cd_adultery_wish_to_name
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id 
AND CD.jurisdiction='DIVORCE'
AND CE.id IN (SELECT MAX(CE2.id) FROM case_event CE2 WHERE CE2.case_data_id=CE.case_data_id)
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Divorce Dump Complete"

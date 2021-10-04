#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
RUNTODAY=$(date -d "today" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=CCD-ET_SINGLES-Initial-7-${RUNTODAY}.csv
TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=no-reply@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="One-off dumps ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "One-off ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}

trap errorHandler ERR

if [[ -z "${CC_ADDRESS}" ]]; then
    CC_COMMAND=""
    CC_LOG_MESSAGE=""
else
    CC_COMMAND="-c ${CC_ADDRESS}"
    CC_LOG_MESSAGE="copied to: ${CC_ADDRESS}"
fi

  QUERY=$(cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
CE.id                  AS CASE_METADATA_EVENT_ID,
CE.case_data_id        AS CE_CASE_DATA_ID,
CE.created_date        AS CE_CREATED_DATE,
trim(CE.case_type_id)  AS CE_CASE_TYPE_ID,
CE.case_type_version   AS CE_CASE_TYPE_VERSION,
trim(CE.data ->>'caseType') AS ce_case_type,
trim(CE.data ->>'receiptDate') AS ce_receipt_date,
trim(CE.data ->>'positionType') AS ce_position_type,
trim(CE.data ->>'multipleReference') AS ce_multiple_ref,
trim(CE.data ->>'ethosCaseReference') AS ce_ethos_case_ref,
trim(CE.data ->>'managingOffice') AS ce_managing_office,
trim(CE.data ->>'claimant_TypeOfClaimant') AS ce_claimant_type,
trim(CE.data ->>'claimantRepresentedQuestion') AS ce_claimant_represented,
trim(CE.data ->>'jurCodesCollection') AS ce_jurisdictions,
trim(CE.data ->>'leadClaimant') AS ce_lead_claimant,
trim(CE.data ->'preAcceptCase' ->>'dateAccepted') AS ce_date_accepted,
trim(CE.data ->>'judgementCollection') AS ce_judgment_collection,
trim(CE.data ->>'hearingCollection') AS ce_hearing_collection,
TRIM(ce.data ->> 'conciliationTrack') AS ce_conciliation_track,
TRIM(ce.data ->> 'dateToPosition') AS ce_date_to_position,
trim(CE.data -> 'representativeClaimantType' ->> 'representative_occupation') AS ce_claimant_repr_occuptn,
trim(CE.data #>> '{repCollection, 0, value, representative_occupation}') AS ce_first_resp_repr_occuptn
FROM case_event CE
WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
ORDER BY CE.created_date
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "ET_SINGLES One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=CCD-SSCS-Initial-SQL-v8.csv
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
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id                                      AS case_metadata_event_id,
CE.case_data_id                               AS ce_case_data_id,
CE.created_date                              AS ce_created_date,
trim(CE.case_type_id)   AS ce_case_type_id,
CE.case_type_version    AS ce_case_type_version,
trim(CE.data ->> 'caseReference') AS CE_BEN_CASE_REF,
trim(CE.data ->> 'caseCreated') AS CE_CASE_CREATED_DATE,
trim(CE.data -> 'appeal' ->> 'receivedVia') AS CE_RECEIVED_VIA,
trim(CE.data -> 'appeal' ->> 'hearingType') AS CE_HEARING_TYPE,
trim(CE.data -> 'appeal' -> 'rep' ->> 'hasRepresentative') AS CE_HAS_REPR,
trim(CE.data -> 'regionalProcessingCenter' ->> 'name') AS CE_REGIONAL_CENTRE,
trim(CE.data ->> 'outcome') AS CE_CASE_OUTCOME,
trim(CE.data ->> 'caseCode') AS CE_CASE_CODE,
trim(CE.data ->> 'directionType') AS CE_DIRECTION_TYPE,
trim(CE.data ->> 'decisionType') AS CE_DECISION_TYPE,
trim(CE.data ->> 'dwpState') AS CE_DWP_STATE,
trim(CE.data ->> 'dwpRegionalCentre') AS CE_DWP_REGIONAL_CENTRE,
trim(CE.data ->> 'createdInGapsFrom') AS CE_GAPS2_ENTRY_POINT,
trim(CE.data ->> 'interlocReviewState') AS CE_INTERLOC_REVIEW_STATE,
trim(CE.data ->> 'scannedDocuments') AS CE_SCANNED_DOCUMENTS_COLL,
trim(CE.data ->> 'dateSentToDwp') AS CE_DATE_SENT_TO_DWP,
trim(CE.data ->> 'reinstatementRegistered') AS CE_REINSTMNT_REGSTRD_DATE,
trim(CE.data ->> 'reinstatementOutcome') AS CE_REINSTMNT_OUTCOME,
trim(CE.data ->> 'urgentHearingRegistered') AS CE_URGNT_HRNG_REGSTRD_DATE,
trim(CE.data ->> 'urgentHearingOutcome') AS CE_URGNT_HRNG_OUTCOME,
trim(CE.data ->> 'isProgressingViaGaps') AS CE_PROGRESSING_VIA_GAPS
FROM case_event CE
WHERE CE.case_type_id = 'Benefit'
ORDER BY CE.created_date ASC
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-v11-prod -h probatemandb-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h dm-store-postgres-db-v11-prod.postgres.database.azure.com -U evidence@dm-store-postgres-db-v11-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@rpe-send-letter-service-db-prod -h rpe-send-letter-service-db-prod.postgres.database.azure.com -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "ET One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

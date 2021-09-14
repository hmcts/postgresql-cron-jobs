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
OUTPUT_FILE_NAME=2689.txt
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
SELECT id
, 'CCD_' || reference AS reference
, TO_CHAR(created_date, 'YYYY-MM-DD') AS created_date
, 'HO_' || TRIM(data ->> 'homeOfficeReferenceNumber') AS CE_HO_REF_NO
, TRIM(data ->> 'appealReferenceNumber') AS CE_APPEAL_REF_NO
, TRIM(data ->> 'appealType') AS CE_APPEAL_TYPE
, TRIM(data ->> 'legalRepName') AS ce_legal_rep_name
, TRIM(data ->> 'legalRepresentativeEmailAddress') AS ce_legal_rep_email
FROM case_data
WHERE case_type_id = 'Asylum'
AND TRIM(data ->> 'appealReferenceNumber') != 'DRAFT')
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-v11-prod -h probatemandb-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h 51.140.184.11 -U ccd@ethosldata -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h dm-store-postgres-db-v11-prod.postgres.database.azure.com -U evidence@dm-store-postgres-db-v11-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@send-letter-service-db-prod -h 51.140.184.11 -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "One-off dumps complete " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

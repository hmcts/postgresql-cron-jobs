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
OUTPUT_FILE_NAME=rdo-8598.txt
TO_ADDRESS=aloknath.datta@HMCTS.NET
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
SELECT data ->> 'previousServiceCaseReference' as claim_numbers, created_date from case_data
WHERE jurisdiction = 'CMC'
AND case_type_id = 'MoneyClaimCase'
AND data ->> 'previousServiceCaseReference' like '%MC%'
AND created_date >= '2020-08-20 06:00:00'
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-prod -h probatemandb-postgres-db-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h dm-store-postgres-db-prod.postgres.database.azure.com -U evidence@dm-store-postgres-db-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@rpe-send-letter-service-db-prod -h rpe-send-letter-service-db-prod.postgres.database.azure.com -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Output from RDO-8790 query " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS}  shashi.kariyappa@HMCTS.NET


log "One-off dump Complete"

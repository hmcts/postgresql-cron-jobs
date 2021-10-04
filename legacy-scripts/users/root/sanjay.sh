#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs
echo -n "Enter a email > "
read email_address

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=primaryApplicantEmailAddress_data_request.txt
TO_ADDRESS=Sanjay.Parekh@HMCTS.NET
CC_ADDRESS=no-reply@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="One-off dumps ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD data request ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT
jsonb_pretty(data) AS referencedata
FROM case_data
WHERE
jurisdiction='PROBATE' AND data->>'primaryApplicantEmailAddress' ILIKE '$email_address')
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "CCD data request " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} alliu.balogun@hmcts.net 


log "CCD data request Complete"

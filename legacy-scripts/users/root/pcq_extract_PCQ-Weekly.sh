#!/bin/bash
# vi:syntax=sh


# Alliu Balogun - 22/7/2020

# PCQ Uptake - https://tools.hmcts.net/jira/browse/RDO-7703

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
#YESTERDAY=20200214
DEFAULT_DATE=$(date +%Y%m%d) 
DAYSAGO=$(date -d "8 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=${DEFAULT_DATE}_PCQ-Weekly.txt
TO_ADDRESS=rordataingress.test@hmcts.net
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="PCQ Dump daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
#  echo -e "Hi\n${dump_failed_error} today" | mail -s "PCQ Weekly Dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
 SELECT * FROM protected_characteristics WHERE completed_date >= '${DAYSAGO}' ORDER BY completed_date) TO STDOUT with csv header ;
EOF
)

psql -U pcquser@pcq-backend-prod -h pcq-backend-prod.postgres.database.azure.com -d pcq -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping PCQ Dump Weekly Report on ${DEFAULT_DATE}"

log "Sending email with PCQ Weekly Dump Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "PCQ Weekly Dump" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS}   


log "PCQ Dump Weekly Report Complete"

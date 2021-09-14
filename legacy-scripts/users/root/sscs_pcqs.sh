#!/bin/bash
# vi:syntax=sh


# Alliu Balogun - 22/7/2020

# PCQ Uptake - https://tools.hmcts.net/jira/browse/RDO-10496

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

#YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
YESTERDAY=20200214
DEFAULT_DATE=$(date +%Y%m%d)
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}_10496.txt
TO_ADDRESS=sean.riley@hmcts.net
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="SSCS Applications created daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
#  echo -e "Hi\n${dump_failed_error} today" | mail -s "PCQ SSCS Applications created ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
 SELECT reference, created_date, state, data->'appeal'->'benefitType'->>'code' AS benefitType, data->'pcqId' AS pcqId   FROM case_data WHERE case_type_id ='Benefit' AND jurisdiction = 'SSCS' AND data->> 'pcqId' IS NOT NULL AND created_date >= '${DAYSAGO}' ORDER BY 2) TO STDOUT with csv header ;
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-api-postgres-db-aat -h ccd-data-store-api-postgres-db-aat.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U pcquser@pcq-backend-prod -h pcq-backend-prod.postgres.database.azure.com -d pcq -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping SSCS Applications created Report on ${DEFAULT_DATE}"

log "Sending email with SSCS Applications created Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "PCQ SSCS Applications created in the last 7 days" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS} alliu.balogun@hmcts.net


log "PCQ SSCS Applications created Report Complete"

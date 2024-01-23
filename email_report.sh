#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
DEFAULT_DATE=$(date +%Y%m%d)
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/tmp
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
OUTPUT_FILE_NAME=${YESTERDAY}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

psql -t -U "${AZURE_DB_USERNAME}"  -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "$(eval "${QUERY}")"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
log "Finished dumping Report on ${YESTERDAY}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"


filesize=$(wc -c ${ATTACHMENT} | awk '{print $1}')
echo "${ATTACHMENT} is $filesize bytes in size"
if [[ $filesize -gt 9000000 ]]
then
  az login --identity
  az storage blob upload --account-name "miapintegrationprod"  --auth-mode login  --container-name "${CONTAINER_NAME}"  --name "${OUTPUT_FILE_NAME}" --file "${ATTACHMENT}"
  log "upload file to storage account"
else
  swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
  log "email sent"
fi
rm ${ATTACHMENT}

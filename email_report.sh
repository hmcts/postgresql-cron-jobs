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
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}.csv

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

psql -U "${AZURE_DB_USERNAME}"  -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "$(eval "${QUERY}")"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
log "Finished dumping Report on ${DEFAULT_DATE}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"
swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"

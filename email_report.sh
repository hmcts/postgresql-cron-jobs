#!/bin/bash
set -fe

: "${PGPASSWORD:?Variable not set or empty}"

function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
DEFAULT_DATE=$(date +%Y%m%d)
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}_pcqDump.txt


function errorHandler() {
  local dump_failed_error="PCQ Dump daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
}

trap errorHandler ERR

if [[ -z "$CC_ADDRESS" ]]; then
    CC_COMMAND=""
    CC_LOG_MESSAGE=""
else
    CC_COMMAND="-c $CC_ADDRESS"
    CC_LOG_MESSAGE="copied to: $CC_ADDRESS"
fi
psql -U "${AZURE_DB_USERNAME}"  -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "$(eval "${QUERY}")"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
cat ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
log "Finished dumping PCQ Dump Report on ${DEFAULT_DATE}"
log "Sending email with PCQ Dump Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"
echo curl -v --request POST --url https://api.sendgrid.com/v3/mail/send --header 'Authorization: Bearer '$SENDGRID_APIKEY'' --header 'Content-Type: application/json' --data '{"personalizations":[{"to":[{"email":"'$TO_ADDRESS'","name":"MO"}],"subject":"Hello, World!"}],"content": [{"type": "text/plain", "value": "Heya!"}],"attachments": [{  "content": "'$(cat ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} | base64)'", "filename": "'${OUTPUT_DIR}/${OUTPUT_FILE_NAME}'", "disposition": "attachment", "content_id": "File"}],"from":{"email":"'$FROM_ADDRESS'","name":""}}'
#curl -v --request POST --url https://api.sendgrid.com/v3/mail/send --header 'Authorization: Bearer '$SENDGRID_APIKEY'' --header 'Content-Type: application/json' --data '{"personalizations":[{"to":[{"email":"'$TO_ADDRESS'","name":"MO"}],"subject":"Hello, World!"}],"content": [{"type": "text/plain", "value": "Heya!"}],"attachments": [{  "content": "'$(cat ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} | base64)'", "filename": "'${OUTPUT_DIR}/${OUTPUT_FILE_NAME}'", "disposition": "attachment", "content_id": "File"}],"from":{"email":"'$FROM_ADDRESS'","name":""}}'
log "PCQ Dump Report Complete"

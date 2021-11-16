#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_HOSTNAME="rd-judicial-api-postgres-db-v11-prod.postgres.database.azure.com"
AZURE_DB_USERNAME="DTS\ Platform\ Operations\ SC@rd-judicial-api-postgres-db-v11-prod"
AZURE_DB="dbjuddata"
SUBJECT='rd-judicial-Record-Count Daily Report'

YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
DEFAULT_DATE=$(date +%Y%m%d)
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/tmp
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}
trap errorHandler ERR
#psql query
echo ""  >> ${ATTACHMENT}
echo "judicial_user_profile Count :"  >> ${ATTACHMENT}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_user_profile;"  >> ${ATTACHMENT}
#psql query
echo ""  >> ${ATTACHMENT}
echo "dbjuddata.judicial_office_appointment Count"  >> ${ATTACHMENT}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_office_appointment;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}

log "Finished dumping Report on ${DEFAULT_DATE}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"

#compress the file if it's large
filesize=$(wc -c ${ATTACHMENT} | awk '{print $1}')
if [[ $filesize -gt 1000000 ]]
then
  gzip ${ATTACHMENT}
  ATTACHMENT=${ATTACHMENT}.gz
fi
echo ${ATTACHMENT}

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"
rm ${ATTACHMENT}
#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_HOSTNAME='rd-location-ref-api-postgres-db-prod.postgres.database.azure.com'
AZURE_DB='dbrdlocationref'
AZURE_DB_USERNAME="DTS\ Platform\ Operations\ SC@rd-location-ref-api-postgres-db-prod"
SUBJECT='LOCATION-REF-DATA-DB Daily Report'

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

echo " =====  dbrdlocationref database Table Counts ===== " > ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "SERVICE_TO_CCD_CASE_TYPE_ASSOC Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT COUNT(*) FROM locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records total Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exception  from locrefdata.dataload_exception_records;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "dataload_schedular_audit today's Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from locrefdata.dataload_schedular_audit where scheduler_end_time::DATE = current_date;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select  * from locrefdata.dataload_exception_records;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "END Count ====== "  >>  ${ATTACHMENT}


log "Finished dumping Report on ${DEFAULT_DATE}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"

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
#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='DTS Platform Operations SC@rd-commondata-api-postgres-db-v11-prod'
AZURE_HOSTNAME='rd-commondata-api-postgres-db-v11-prod.postgres.database.azure.com'
AZURE_DB='dbcommondata'
SUBJECT='rd-commondata-Record-Count Daily Report'
TO_ADDRESS='dlrefdatasupport@hmcts.net'
CC_ADDRESS='dts-refdata-team@hmcts.net,manukundloo.sinha@hmcts.net'
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
echo " =====  rd-commondata database Table Counts ===== " > ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "list of values Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from public.list_of_values;"  >> ${ATTACHMENT}

echo "Flag Details Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from public.flag_details;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records total Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT COUNT(*) AS total_exception FROM public.dataload_exception_records;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "dataload_schedular_audit total Count:"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT COUNT(*) FROM public.dataload_schedular_audit WHERE scheduler_end_time::DATE = current_date-1;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records last batch records:"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT der.table_name, der.error_description, der.field_in_error, count(der.error_description) FROM public.dataload_exception_records der WHERE der.updated_timestamp::DATE = current_date-1 GROUP BY der.table_name, der.error_description, der.field_in_error;"  >> ${ATTACHMENT}

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

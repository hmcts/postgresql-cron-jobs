#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='DTS JIT Access rd DB Reader SC'
AZURE_HOSTNAME='rd-judicial-ref-api-postgres-db-v16-prod.postgres.database.azure.com'
AZURE_DB='dbjuddata'
SUBJECT='rd-judicial-Record-Count Daily Report'
TO_ADDRESS='dlrefdatasupport@hmcts.net'
CC_ADDRESS='dts-refdata-team@hmcts.net'
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
echo " =====  rd-judicial database Table Counts ===== " > ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_user_profile Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_user_profile;"  >> ${ATTACHMENT}

echo "judicial_office_appointment Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_office_appointment;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_office_authorisation Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from dbjuddata.judicial_office_authorisation;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "dataload_schedular_job Publishing status :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select dsj.publishing_status,dsj.job_start_time,dsj.job_end_time from dbjuddata.dataload_schedular_job dsj where dsj.job_end_time::DATE = current_date;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_office_appointment  Extracted Date :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select distinct(extracted_date) from dbjuddata.judicial_office_appointment;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "base_location_type Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from dbjuddata.base_location_type;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "region_type Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from dbjuddata.region_type;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "dataload_schedular_audit total Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_audits from dbjuddata.dataload_schedular_audit;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records total Count :"  >> ${ATTACHMENT}
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exception from dbjuddata.dataload_exception_records;"  >> ${ATTACHMENT}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_schedular_audit today's Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from dbjuddata.dataload_schedular_audit where scheduler_end_time::DATE = current_date;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "dataload_exception_records today's Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select der.table_name,  der.error_description, der.field_in_error, count(der.error_description) from dbjuddata.dataload_exception_records der where der.updated_timestamp::DATE = current_date group by der.table_name, der.error_description, der.field_in_error;"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_user_profile exceptions records today's Count :"  >> ${ATTACHMENT}
psql  -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_personal_today from dbjuddata.dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_user_profile';"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_office_appointment exceptions records today's Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_appointments_today from dbjuddata.dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_appointment';"  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "judicial_office_authorisation exceptions records today's Count :"  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_authorizations_today from dbjuddata.dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_authorisation';"  >> ${ATTACHMENT}
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
#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

AZURE_HOSTNAME="rd-judicial-api-postgres-db-prod.postgres.database.azure.com"
AZURE_DB_USERNAME="dbjuddata@rd-judicial-api-postgres-db-prod"
AZURE_DB="dbjuddata"

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=dbjuddata-$DEFAULT_DATE.txt
TO_ADDRESS=DLRefDataSupport@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="DBJUDDATA DB Count ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "One-off ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}

trap errorHandler ERR

if [[ -z "${CC_ADDRESS}" ]]; then
    CC_COMMAND=""
    CC_LOG_MESSAGE=""
else
    CC_COMMAND="-c ${CC_ADDRESS}"
    CC_LOG_MESSAGE="copied to: ${CC_ADDRESS}"
fi
##
echo " =====  rd-judicial database Table Counts ===== " > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_user_profile Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_user_profile;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_office_appointment Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from dbjuddata.judicial_office_appointment;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_office_authorisation Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from judicial_office_authorisation;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "base_location_type Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from dbjuddata.base_location_type;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "region_type Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) from dbjuddata.region_type;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_schedular_audit total Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_audits from dbjuddata.dataload_schedular_audit;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_exception_records total Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exception  from dataload_exception_records;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_schedular_audit today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from dataload_schedular_audit where scheduler_end_time::DATE = current_date;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_exception_records today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from dataload_exception_records  where updated_timestamp::DATE = current_date;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_user_profile exceptions records today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_personal_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_user_profile';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_office_appointment exceptions records today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_appointments_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_appointment';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "judicial_office_authorisation exceptions records today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exceptions_authorizations_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_authorisation';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "END Count ====== "  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}



##
log "DBJUDDATA DB Count ${DEFAULT_DATE}"

log "DBJUDDATA DB Count results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

#echo -e " Find attached the dbjuddata count" | mail -s "dbjuddata Row Count " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS}

echo -e " Find attached the dbjuddata count" | mail -s "dbjuddata Row Count " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 

log "DBJUDDATA DB Count Complete"

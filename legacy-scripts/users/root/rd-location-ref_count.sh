#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

AZURE_HOSTNAME="rd-location-ref-api-postgres-db-prod.postgres.database.azure.com"
AZURE_DB_USERNAME="dbrdlocationref@rd-location-ref-api-postgres-db-prod"
AZURE_DB="dbrdlocationref"

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=dbrdlocationref-$DEFAULT_DATE.txt
TO_ADDRESS=DLRefDataSupport@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="LOCATION-REF-DATA DB Count ${DEFAULT_DATE}"

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
echo " =====  rd-location-ref database Table Counts ===== " > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "SERVICE_TO_CCD_CASE_TYPE_ASSOC Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count (*) from locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_exception_records total Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select count(*) as total_exception  from locrefdata.dataload_exception_records;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_schedular_audit today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from locrefdata.dataload_schedular_audit where scheduler_end_time::DATE = current_date;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_exception_records today's Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select * from locrefdata.dataload_exception_records  where updated_timestamp::DATE = current_date;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "END Count ====== "  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}



##
log "LOCATION-REF-DATA DB Count ${DEFAULT_DATE}"

log "LOCATION-REF-DATA DB Count results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e " Find attached the LOCATION-REF-DATA count" | mail -s "LOCATION-REF-DATA Row Count " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "LOCATION-REF-DATA DB Count Complete"

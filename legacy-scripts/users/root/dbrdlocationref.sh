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
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=dbjuddata-$DEFAULT_DATE.txt
TO_ADDRESS=abhijit.diwan@hmcts.net
CC_ADDRESS=shashank.rastogi@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="dbrdlocationref DB Count ${DEFAULT_DATE}"

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

echo " =====  dbrdlocationref database Table Counts ===== " > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "SERVICE_TO_CCD_CASE_TYPE_ASSOC Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT COUNT(*) FROM locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_schedular_audit Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select  * from locrefdata.dataload_schedular_audit;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "dataload_exception_records Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -t -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select  * from locrefdata.dataload_exception_records;"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "END Count ====== "  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}




##
log "dbrdlocationref DB Count ${DEFAULT_DATE}"

log "dbrdlocationref DB Count results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e " Find attached the dbrdlocationref count" | mail -s "dbrdlocationref Row Count " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} Sourav.Bhattacharya@HMCTS.NET Sudip.Datta@hmcts.net


log "dbrdlocationref DB Count Complete"

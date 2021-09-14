#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

AZURE_HOSTNAME="51.140.184.11"
AZURE_DB_USERNAME="ccd@ccd-data-store-api-postgres-db-prod"
AZURE_DB="ccd_data_store"

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=RDO-10059-$DEFAULT_DATE.txt
TO_ADDRESS=thirumurugan.devarajan@HMCTS.NET
CC_ADDRESS=steve.liddiard@Justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Claim data extract DB Count ${DEFAULT_DATE}"

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
echo " ========== " > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo " Query:1 claims created from yesterday for user1 :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select data ->> 'previousServiceCaseReference' as claim_ref, data ->> 'id' as ccd_reference_number ,state as current_state, created_date, data -> 'respondents' -> 0 -> 'value' ->> 'defendantId' from case_data where jurisdiction = 'CMC' and  case_type_id= 'MoneyClaimCase' and date(created_date) >= date(current_timestamp) - 1  and data -> 'respondents' -> 0 -> 'value' ->> 'defendantId' = '20232';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "Query:2 claims created from yesterday for user2 Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select data ->> 'previousServiceCaseReference' as claim_ref, data ->> 'id' as ccd_reference_number ,state as current_state, created_date, data -> 'respondents' -> 0 -> 'value' ->> 'defendantId' from case_data where jurisdiction = 'CMC' and case_type_id= 'MoneyClaimCase' and date(created_date) >= date(current_timestamp) - 1 and data -> 'respondents' -> 0 -> 'value' ->> 'defendantId' = '6877';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "Query:3 claim issued from yesterday against user1 Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select data ->> 'previousServiceCaseReference' as claim_ref, data ->> 'id' as ccd_reference_number ,state as current_state, created_date, data -> 'respondents' -> 0 -> 'value' -> 'claimantProvidedDetail' ->> 'emailAddress' as emailId from case_data where jurisdiction = 'CMC' and case_type_id= 'MoneyClaimCase' and date(created_date) >= date(current_timestamp) - 1 and data -> 'respondents' -> 0 -> 'value' -> 'claimantProvidedDetail' ->> 'emailAddress' = 'fawad.mir@loveholidays.com';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "Query:4 claim issued from yesterday against user2 :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ${AZURE_DB_USERNAME} -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select data ->> 'previousServiceCaseReference' as claim_ref, data ->> 'id' as ccd_reference_number ,state as current_state, created_date, data -> 'respondents' -> 0 -> 'value' -> 'claimantProvidedDetail' ->> 'emailAddress' as emailId from case_data where jurisdiction = 'CMC' and case_type_id= 'MoneyClaimCase' and date(created_date) >= date(current_timestamp) - 1 and data -> 'respondents' -> 0 -> 'value' -> 'claimantProvidedDetail' ->> 'emailAddress' = 'customerrelations@teletext-holidays.co.uk';"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}



echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "END Count ====== "  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}



##
log "Claim data extract DB Count ${DEFAULT_DATE}"

log "Claim data extract DB Count results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e " Find attached the dbjuddata count" | mail -s "Claim data extract DB Row Count " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} alliu.balogun@hmcts.net 


log "Claim data extract DB Count Complete"

#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=2019 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=DTSPO-3315-$DEFAULT_DATE.txt
TO_ADDRESS=thirumurugan.devarajan@HMCTS.NET
CC_ADDRESS=shashi.kariyappa@HMCTS.NET
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="One-off dumps ${DEFAULT_DATE}"

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

  QUERY=$(cat <<EOF
COPY (
select data -> 'previousServiceCaseReference' as claim_number, state , data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->>'submittedOn' as submittted_timetsamp, TO_DATE(data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->>'submittedOn','YYYY-MM-DD') as submitted_date from case_data
WHERE jurisdiction = 'CMC'
AND case_type_id = 'MoneyClaimCase'
AND TO_DATE(data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->>'submittedOn','YYYY-MM-DD') = CURRENT_DATE - 1
AND data -> 'respondents' -> 0 -> 'value' ->> 'responseFreeMediationOption' = 'YES'
AND data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->> 'freeMediationOption' = 'YES'
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "Record Count :"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql  -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "select count(*) from case_data WHERE jurisdiction = 'CMC' AND case_type_id = 'MoneyClaimCase' AND TO_DATE(data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->>'submittedOn','YYYY-MM-DD') = CURRENT_DATE - 1 AND data -> 'respondents' -> 0 -> 'value' ->> 'responseFreeMediationOption' = 'YES' AND data -> 'respondents' -> 0 -> 'value' -> 'claimantResponse' ->> 'freeMediationOption' = 'YES';" >>  ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo ""  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
echo "END"  >> ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Need List of Created claims complete " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} aloknath.datta@HMCTS.NET dilip.samra@HMCTS.NET alliu.balogun@hmcts.net


log "One-off dump Complete"

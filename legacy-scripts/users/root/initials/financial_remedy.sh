#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
RUNTODAY=$(date -d "today" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=CCD-FINANCIAL_REMEDY-Initial-${RUNTODAY}.csv
TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=no-reply@hmcts.net
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
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,

CE.id                                      AS case_metadata_event_id,

CE.case_data_id                               AS ce_case_data_id,

CE.created_date                              AS ce_created_date,

trim(CE.case_type_id)   AS ce_case_type_id,

CE.case_type_version    AS ce_case_type_version,

trim(CE.data ->> 'issueDate') AS CE_ISSUED_DATE,

trim(CE.data ->> 'orderDirectionDate') AS CE_ORDER_DATE,

trim(CE.data ->> 'divorceCaseNumber') AS CE_DIVORCE_CASE_NUM,

trim(CE.data ->> 'natureOfApplication2') AS CE_ORDER_TYPES,

trim(CE.data ->> 'orderDirectionJudge') AS CE_JUDGE_TYPE,

TRIM(ce.data ->> 'applicantRepresented') AS ce_applicant_represented,

TRIM(ce.data ->> 'appRespondentRep') AS ce_respondent_represented,

TRIM(ce.data ->> 'paperApplication') AS ce_paper_application,

TRIM(ce.data ->> 'regionList') AS ce_region,

TRIM(ce.data ->> 'assignedToJudge') AS ce_assigned_to_judge

FROM case_event CE

WHERE CE.case_type_id = 'FinancialRemedyMVP2'

AND CE.created_date >= (current_date-35 + time '00:00')

AND CE.created_date < (current_date + time '00:00')

ORDER BY CE.created_date ASC
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "FRemedy One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

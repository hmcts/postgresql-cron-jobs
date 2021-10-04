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
OUTPUT_FILE_NAME=CCD-FPLAW-Initial-${RUNTODAY}.csv
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
SELECT TO_CHAR(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date
, ce.id AS case_metadata_event_id
, ce.case_data_id AS ce_case_data_id
, ce.created_date AS ce_created_date
, TRIM(ce.case_type_id) AS ce_case_type_id
, ce.case_type_version AS ce_case_type_version
, TRIM(ce.data ->> 'dateSubmitted') AS ce_date_submitted
, TRIM(ce.data ->> 'dateOfIssue') AS ce_date_of_issue
, TRIM(ce.data ->> 'caseLocalAuthority') AS ce_case_local_authority
, TRIM(ce.data ->> 'familyManCaseNumber') AS ce_fm_case_number
, TRIM(ce.data ->> 'internationalElement') AS ce_international_element
, TRIM(ce.data ->> 'caseCompletionDate') AS ce_case_completion_date
, TRIM(ce.data -> 'returnApplication' ->> 'reason') AS ce_returned_reason
, TRIM(ce.data -> 'closeCaseTabField' ->> 'date') AS ce_close_case_date
, TRIM(ce.data -> 'closeCaseTabField' ->> 'fullReason') AS ce_close_case_full_reason
, TRIM(ce.data -> 'closeCaseTabField' ->> 'partialReason') AS ce_close_case_partial_reason
, TRIM(ce.data -> 'orders' ->> 'orderType') AS ce_requested_order_type
, ce.data ->> 'orderCollection' AS ce_generated_order_coll
, ce.data ->> 'hearingDetails' AS ce_hearing_coll
, ce.data ->> 'cancelledHearingDetails' AS ce_cancelled_hearing_coll
, ce.data ->> 'children1' AS ce_children_coll
, ce.data ->> 'expertReport' AS ce_expert_report_coll
, TRIM(ce.data ->> 'caseExtensionTimeList') AS ce_case_ext_time_list
, TRIM(ce.data ->> 'caseExtensionTimeConfirmationList') AS ce_case_ext_time_conf_list
, TRIM(ce.data ->> 'caseExtensionReasonList') AS ce_case_ext_reason_list
, TRIM(ce.data -> 'allocationDecision' ->> 'proposal') AS ce_allocated_judge_tier
, TRIM(ce.data -> 'allocationDecision' ->> 'proposalReason') AS ce_allocation_reason
FROM case_event ce
WHERE ce.case_type_id = 'CARE_SUPERVISION_EPO'
ORDER BY ce.created_date
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "FPLA One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

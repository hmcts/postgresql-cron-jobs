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
OUTPUT_FILE_NAME=CCD-CIVIL-Initial-${RUNTODAY}.csv
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
ce.id AS case_metadata_event_id,
ce.case_data_id AS ce_case_data_id,
ce.created_date AS ce_created_date,
TRIM(ce.case_type_id) AS ce_case_type_id,
ce.case_type_version AS ce_case_type_version,
TRIM(CE.data -> 'courtLocation' ->> 'applicantPreferredCourt') AS ce_court_location_code,
TRIM(ce.data -> 'applicant1' ->> 'type') AS ce_applicant_type,
ce.data ->> 'applicant1' AS ce_applicant_obj,
TRIM(ce.data -> 'respondent1' ->> 'type') AS ce_respondent_type,
ce.data ->> 'respondent1' AS ce_respondent_obj,
TRIM(CE.data ->> 'respondent1Represented') AS ce_respondent_represented,
TRIM(CE.data -> 'claimValue' ->> 'statementOfValueInPennies') AS ce_claim_value_pennies,
TRIM(CE.data ->> 'claimType') AS ce_claim_type,
TRIM(CE.data ->> 'claimTypeOther') AS ce_claim_type_other,
TRIM(CE.data ->> 'personalInjuryType') AS ce_personal_injury_type,
TRIM(CE.data ->> 'personalInjuryTypeOther') AS ce_personal_injury_type_other,
TRIM(CE.data ->> 'allocatedTrack') AS ce_allocated_track,
TRIM(CE.data -> 'claimFee' ->> 'calculatedAmountInPence') AS ce_claim_fee_amount_pennies,
TRIM(CE.data ->> 'issueDate') AS ce_issue_date,
TRIM(CE.data ->> 'legacyCaseReference') AS ce_legacy_reference,
TRIM(CE.data -> 'withdrawClaim' ->> 'date') AS ce_withdraw_claim_date,
TRIM(CE.data -> 'withdrawClaim' ->> 'reason') AS ce_withdraw_claim_reason,
TRIM(CE.data -> 'discontinueClaim' ->> 'date') AS ce_discontinue_claim_date,
TRIM(CE.data -> 'discontinueClaim' ->> 'reason') AS ce_discontinue_claim_reason,
TRIM(CE.data ->> 'submittedDate') AS ce_submitted_date,
TRIM(CE.data ->> 'respondent1ResponseDate') AS ce_respondent_response_date,
TRIM(CE.data ->> 'claimIssuedPaymentDetails') AS ce_payment_details_obj,
TRIM(CE.data ->> 'claimDismissedDeadline') AS ce_claim_dismissed_deadline_date,
TRIM(CE.data -> 'claimProceedsInCaseman' ->> 'date') AS ce_proceeds_in_caseman_date,
TRIM(CE.data -> 'claimProceedsInCaseman' ->> 'reason') AS ce_proceeds_in_caseman_reason,
TRIM(CE.data -> 'claimProceedsInCaseman' ->> 'other') AS ce_proceeds_in_caseman_other,
TRIM(CE.data ->> 'paymentSuccessfulDate') AS ce_payment_successful_date,
TRIM(CE.data ->> 'applicant1ResponseDate') AS ce_applicant_response_date,
TRIM(CE.data ->> 'takenOfflineDate') AS ce_taken_offline_date,
TRIM(CE.data ->> 'claimDismissedDate') AS ce_claim_dismissed_date,
TRIM(CE.data ->> 'applicant1ProceedWithClaim') AS ce_applicant_proceed_with_claim,
TRIM(CE.data ->> 'respondent1ClaimResponseType') AS ce_respondent_response_type,
TRIM(CE.data -> 'respondent1DQRequestedCourt' ->> 'responseCourtCode') AS ce_respondent_requested_court,
TRIM(CE.data ->> 'respondentSolicitor1AgreedDeadlineExtension') AS ce_resp_solr_deadline_extsn
FROM case_event ce
WHERE ce.case_type_id = 'CIVIL'
ORDER BY ce.created_date ASC
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "CIVIL One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

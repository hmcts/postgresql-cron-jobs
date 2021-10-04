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
OUTPUT_FILE_NAME=CCD-IA-Initial-v10.csv
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
CE.id AS case_metadata_event_id,
CE.case_data_id AS ce_case_data_id,
CE.created_date AS ce_created_date,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
trim(CE.data ->> 'homeOfficeDecisionDate') AS CE_HO_DECISION_DATE,
trim(CE.data ->> 'hearingCentre') AS CE_HEARING_CENTRE,
trim(CE.data ->> 'homeOfficeReferenceNumber') AS CE_HO_REF_NO,
trim(CE.data ->> 'appealReferenceNumber') AS CE_APPEAL_REF_NO,
trim(CE.data ->> 'appealType') AS CE_APPEAL_TYPE,
trim(CE.data ->> 'appealResponse') AS CE_APPEAL_RESPONSE,
trim(CE.data ->> 'listCaseHearingLength') AS CE_HEARING_LENGTH,
trim(CE.data ->> 'appellantNationalities') AS CE_NATIONALITY,
trim(CE.data ->> 'applicationType') AS CE_APPLICATION_TYPE,
trim(CE.data ->> 'applicationDecision') AS CE_APPLICATION_DECISION,
trim(CE.data ->> 'endAppealDate') AS CE_END_APPEAL_DATE,
trim(CE.data ->> 'endAppealOutcomeReason') AS CE_CASE_OUTCOME_REASON,
trim(CE.data ->> 'endAppealOutcome') AS CE_CASE_OUTCOME,
trim(CE.data ->> 'submissionOutOfTime') AS CE_SUBMISSION_OUT_OF_TIME,
trim(CE.data ->> 'appealSubmissionDate') AS CE_APPEAL_SUBMISSION_DATE,
trim(CE.data ->> 'listCaseHearingDate') AS CE_LIST_CASE_HEARING_DATE,
trim(CE.data ->> 'isDecisionAllowed') AS CE_IS_DECISION_ALLOWED,
CE.data -> 'applications' AS CE_APPLICATIONS,
trim(CE.data -> 'checklist' ->> 'checklist5') AS CE_IN_COUNTRY,
trim(CE.data ->> 'singleSexCourt') AS CE_SINGLE_SEX_COURT,
trim(CE.data ->> 'singleSexCourtType') AS CE_SINGLE_SEX_COURT_TYPE,
trim(CE.data ->> 'physicalOrMentalHealthIssues') AS CE_HEALTH_ISSUES,
trim(CE.data ->> 'pastExperiences') AS CE_PAST_EXPERIENCES,
trim(CE.data ->> 'multimediaEvidence') AS CE_MM_EVIDENCE,
trim(CE.data ->> 'inCameraCourt') AS CE_IN_CAMERA_COURT,
trim(CE.data ->> 'additionalRequests') AS CE_ADDITIONAL_REQUESTS,
trim(CE.data ->> 'listCaseRequirementsVulnerabilities') AS CE_CASE_REQ_VULNERABILITIES,
trim(CE.data ->> 'ftpaAppellantDecisionOutcomeType') AS CE_APP_DECISION_OUTCOMETYPE,
CE.data -> 'caseFlags' AS CE_CASEFLAGS,
CE.data -> 'checklist' AS CE_CHECKLIST,
TRIM(CE.data ->> 'legalRepCompany') AS CE_LEGAL_REP_COMPANY,
TRIM(CE.data ->> 'appealDate') AS CE_APPEAL_DATE,
TRIM(CE.data ->> 'applicationChangeDesignatedHearingCentre') AS CE_CHANGE_HEARING_CENTRE,
TRIM(CE.data ->> 'sendDirectionDateDue') AS CE_SEND_DIRECTION_DATE_DUE,
TRIM(CE.data ->> 'sendDirectionParties') AS CE_SEND_DIRECTION_PARTIES,
TRIM(CE.data ->> 'feeAmount') AS CE_FEE_AMOUNT,
TRIM(CE.data -> 'directions' -> 0 -> 'value' ->> 'tag') AS CE_FIRST_DIRECTION_TYPE,
TRIM(CE.data ->> 'paymentStatus') AS CE_PAYMENT_STATUS,
TRIM(CE.data ->> 'decisionHearingFeeOption') AS CE_DECISION_HEARING_FEE_OPTN,
TRIM(CE.data ->> 'paymentDate') AS CE_PAYMENT_DATE,
TRIM(CE.data ->> 'paAppealTypePaymentOption') AS CE_PA_APPEAL_TYPE_PAYMT_OPTN,
TRIM(CE.data ->> 'eaHuAppealTypePaymentOption') AS CE_EAHU_APPEAL_TYPE_PAYMT_OPTN,
TRIM(CE.data ->> 'journeyType') AS CE_JOURNEY_TYPE,
TRIM(CE.data ->> 'ftpaAppellantDecisionOutcomeType') AS CE_APPELLANT_FTPA_OUTCOME,
TRIM(CE.data ->> 'ftpaRespondentDecisionOutcomeType') AS CE_RESPONDENT_FTPA_OUTCOME,
TRIM(CE.data ->> 'ftpaAppellantRjDecisionOutcomeType') AS CE_APPELLANT_FTPA_RJ_OUTCOME,
TRIM(CE.data ->> 'ftpaRespondentRjDecisionOutcomeType') AS CE_RESPONDENT_FTPA_RJ_OUTCOME,
TRIM(CE.data ->> 'ftpaAppellantSubmissionOutOfTime') AS CE_APPELLANT_FTPA_SUBMSN_OOT,
TRIM(CE.data ->> 'ftpaRespondentSubmissionOutOfTime') AS CE_RESPONDENT_FTPA_SUBMSN_OOT
FROM case_event CE
WHERE CE.case_type_id = 'Asylum'
ORDER BY CE.created_date ASC
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-prod -h probatemandb-postgres-db-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ccd@ccd-data-store-api-postgres-db-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h dm-store-postgres-db-prod.postgres.database.azure.com -U evidence@dm-store-postgres-db-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@rpe-send-letter-service-db-prod -h rpe-send-letter-service-db-prod.postgres.database.azure.com -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "IA One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

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
OUTPUT_FILE_NAME=CCD-CMC-Initial-SQL-v5.csv
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
TRIM(ce.data ->> 'referenceNumber') AS CE_REFERENCE_NUMBER,
TRIM(ce.data ->> 'feeAmountInPennies') AS CE_FEE_AMOUNT_PENCE,
TRIM(ce.data ->> 'reason') AS CE_CASE_REASON,
TRIM(ce.data ->> 'feeAccountNumber') AS CE_FEE_ACCOUNT_NUMBER,
TRIM(ce.data ->> 'preferredCourt') AS CE_PREFERRED_COURT,
TRIM(ce.data ->> 'feeCode') AS CE_FEE_CODE,
TRIM(ce.data ->> 'totalAmount') AS CE_TOTAL_AMOUNT,
TRIM(ce.data ->> 'issuedOn') AS CE_ISSUED_ON,
TRIM(ce.data ->> 'submittedOn') AS CE_SUBMITTED_ON,
TRIM(ce.data ->> 'id') AS CE_CLAIM_STORE_ID,
TRIM(ce.data ->> 'features') AS CE_CASE_FEATURES,
TRIM(ce.data ->> 'subjectName') AS CE_SUBJECT_NAME,
TRIM(ce.data ->> 'subjectType') AS CE_SUBJECT_TYPE,
TRIM(ce.data ->> 'paymentId') AS CE_PAYMENT_ID,
TRIM(ce.data ->> 'paymentAmount') AS CE_PAYMENT_AMOUNT,
TRIM(ce.data ->> 'paymentReference') AS CE_PAYMENT_REFERENCE,
TRIM(ce.data ->> 'paymentStatus') AS CE_PAYMENT_STATUS,
TRIM(ce.data ->> 'paymentDateCreated') AS CE_PAYMENT_DATE_CREATED,
TRIM(ce.data ->> 'migratedFromClaimStore') AS CE_MIGRATED_FROM_CLAIM_STORE,
TRIM(ce.data #>> '{applicants, 0, value, partyDetail, type}') AS CE_FIRST_CLAIMANT_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, partyDetail, type}') AS CE_FIRST_RESPONDENT_TYPE,
TRIM(ce.data #>> '{applicants, 0, value, representativeOrganisationName}') AS CE_CLAIMANT_REPR_ORG_NAME,
TRIM(ce.data #>> '{respondents, 0, value, representativeOrganisationName}') AS CE_RESPONDENT_REPR_ORG_NAME,
TRIM(ce.data ->> 'previousServiceCaseReference') AS CE_PREVIOUS_CASE_REFERENCE,
TRIM(ce.data ->> 'interestBreakDownAmount') AS CE_INTEREST_BRKDWN_AMOUNT,
TRIM(ce.data ->> 'currentInterestAmount') AS CE_INTEREST_CURRENT_AMOUNT,
TRIM(ce.data #>> '{respondents, 0, value, responseSubmittedOn}') AS CE_RESPONSE_SUBMITTED_ON,
TRIM(ce.data #>> '{respondents, 0, value, responseType}') AS CE_RESPONSE_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, responseDefenceType}') AS CE_RESPONSE_DEFENCE_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, mediationFailedReason}') AS CE_MEDIATION_FAILED_REASON,
TRIM(ce.data #>> '{respondents, 0, value, mediationSettlementReachedAt}') AS CE_MEDIATION_SETTLED_ON,
TRIM(ce.data #>> '{respondents, 0, value, responseFreeMediationOption}') AS CE_RESPONSE_FREE_MEDIATN_OPTN,
TRIM(ce.data #>> '{respondents, 0, value, settlementReachedAt}') AS CE_SETTLED_ON,
TRIM(ce.data #>> '{respondents, 0, value, claimantResponse, claimantResponseType}') AS CE_CLAIMANT_RESPONSE_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, claimantResponse, freeMediationOption}') AS CE_CLAIMANT_FREE_MEDIATN_OPTN,
TRIM(ce.data #>> '{respondents, 0, value, claimantResponse, submittedOn}') AS CE_CLAIMANT_SUBMITTED_ON,
TRIM(ce.data #>> '{respondents, 0, value, paidInFullDate}') AS CE_PAID_IN_FULL_DATE,
TRIM(ce.data #>> '{directionOrder, createdOn}') AS CE_DIRECTION_ORDER_DATE,
TRIM(ce.data #>> '{respondents, 0, value, countyCourtJudgmentRequest, type}') AS CE_JUDGMENT_REQUEST_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, countyCourtJudgmentRequest, requestedDate}') AS CE_JUDGMENT_REQUEST_DATE,
TRIM(ce.data #>> '{respondents, 0, value, claimantProvidedDetail, type}') AS CE_CLAIMANT_PROVIDED_RESP_TYPE,
TRIM(ce.data #>> '{respondents, 0, value, paperFormIssueDate}') AS ce_paper_form_issue_date,
ce.data ->> 'scannedDocuments' AS ce_scanned_documents_coll
FROM case_event ce
WHERE ce.case_type_id = 'MoneyClaimCase'
ORDER BY ce.created_date ASC
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-v11-prod -h probatemandb-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h dm-store-postgres-db-v11-prod.postgres.database.azure.com -U evidence@dm-store-postgres-db-v11-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@rpe-send-letter-service-db-prod -h rpe-send-letter-service-db-prod.postgres.database.azure.com -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "CMC One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

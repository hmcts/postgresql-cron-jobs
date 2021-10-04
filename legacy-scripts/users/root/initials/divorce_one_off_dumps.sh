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
OUTPUT_FILE_NAME=CCD-DIVORCE-Initial-${RUNTODAY}.csv
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
CASE WHEN trim(CE.data ->> 'D8DivorceUnit') IS NULL THEN 'OTHER' ELSE trim(CE.data ->> 'D8DivorceUnit') END AS ce_divorce_unit,
trim(CE.data ->> 'D8PetitionerContactDetailsConfidential') AS ce_contact_confidential,
trim(CE.data ->> 'D8HelpWithFeesNeedHelp') AS ce_need_help_with_fees,
trim(CE.data ->> 'D8FinancialOrder') AS ce_financial_order,
trim(CE.data ->> 'D8ReasonForDivorce') AS ce_reason_for_divorce,
trim(CE.data ->> 'D8DivorceClaimFrom') AS ce_divorce_claim_from,
trim(CE.data ->> 'D8ReasonForDivorceAdulteryWishToName') as ce_adultery_wish_to_name,
trim(CE.data ->> 'D8caseReference') AS ce_case_reference,
trim(CE.data ->> 'D8legalProcess') AS CE_LEGAL_PROCESS,
trim(CE.data ->> 'createdDate') AS CE_CASE_CREATED_DATE,
trim(CE.data ->> 'receivedDate') AS CE_CASE_RECEIVED_DATE,
trim(CE.data ->> 'IssueDate') AS CE_CASE_ISSUE_DATE,
trim(CE.data ->> 'ReceivedAOSfromRespDate') AS CE_AOS_RECEIVED_RESP_DATE,
trim(CE.data ->> 'ReceivedAnswerFromRespDate') AS CE_ANSWER_RECEIVED_RESP_DATE,
trim(CE.data ->> 'ReceivedAosFromCoRespDate') AS CE_AOS_RECEIVED_CORESP_DATE,
trim(CE.data ->> 'ReceivedAnswerFromCoRespDate') AS CE_ANSWER_RECEIVED_CORESP_DATE,
trim(CE.data ->> 'DNApplicationSubmittedDate') AS CE_DN_SUBMITTED_DATE,
trim(CE.data ->> 'RespDefendsDivorce') AS CE_RESP_DEFENDS,
trim(CE.data ->> 'CoRespDefendsDivorce') AS CE_CORESP_DEFENDS,
trim(CE.data ->> 'PetitionerSolicitorFirm') AS ce_petitioner_solicitor_firm,
trim(CE.data ->> 'D8RespondentSolicitorCompany') AS ce_d8respondent_solicitor_co,
trim(CE.data ->> 'LanguagePreferenceWelsh') AS ce_lang_pref_welsh,
trim(CE.data ->> 'ServiceApplicationType') AS ce_service_applctn_type,
trim(CE.data ->> 'ReceivedServiceApplicationDate') AS ce_service_applctn_date,
trim(CE.data ->> 'ReceivedServiceAddedDate') AS ce_service_added_date,
trim(CE.data ->> 'ServiceApplicationGranted') AS ce_service_applctn_granted,
trim(CE.data ->> 'ServiceApplicationDecisionDate') AS ce_service_applctn_decsn_date,
trim(CE.data ->> 'GeneralReferralType') AS ce_general_refrrl_type,
trim(CE.data ->> 'GeneralApplicationAddedDate') AS ce_general_applctn_added_date,
trim(CE.data ->> 'GeneralApplicationReferralDate') AS ce_general_applctn_refrrl_date,
trim(CE.data ->> 'GeneralReferralDecision') AS ce_general_refrrl_decsn,
trim(CE.data ->> 'GeneralReferralDecisionDate') AS ce_general_refrrl_decsn_date,
trim(CE.data ->> 'D8PetitionerFirstName') AS ce_petitioner_first_name,
trim(CE.data ->> 'D8PetitionerLastName') AS ce_petitioner_last_name,
trim(CE.data ->> 'D8RespondentFirstName') AS ce_respondent_first_name,
trim(CE.data ->> 'D8RespondentLastName') AS ce_respondent_last_name,
trim(CE.data ->> 'D8InferredPetitionerGender') AS ce_petitioner_gender,
trim(CE.data ->> 'D8InferredRespondentGender') AS ce_respondent_gender,
trim(CE.data ->> 'D8MarriageDate') AS ce_marriage_date,
trim(CE.data ->> 'D8MarriagePetitionerName') AS ce_marriage_petitioner_name,
trim(CE.data ->> 'D8MarriageRespondentName') AS ce_marriage_respondent_name,
CE.data ->> 'GeneralReferrals' AS ce_general_refrrl_coll,
trim(CE.data -> 'PreviousCaseId' ->> 'CaseReference') AS ce_previous_case_ref,
trim(CE.data ->> 'respondentSolicitorRepresented') AS ce_respondent_solicitor_repr
FROM case_event CE
WHERE CE.case_type_id = 'DIVORCE'
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

echo -e "" | mail -s "Divorce One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

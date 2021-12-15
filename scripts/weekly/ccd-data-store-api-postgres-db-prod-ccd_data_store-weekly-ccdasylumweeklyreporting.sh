#!/bin/bash

cat <<EOF
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
TRIM(CE.data ->> 'ftpaRespondentSubmissionOutOfTime') AS CE_RESPONDENT_FTPA_SUBMSN_OOT,
TRIM(CE.data -> 'actualCaseHearingLength' ->> 'hours') AS CE_ACTUAL_HEARING_LENGTH_HRS,
TRIM(CE.data -> 'actualCaseHearingLength' ->> 'minutes') AS CE_ACTUAL_HEARING_LENGTH_MINS,
TRIM(CE.data ->> 'appealOutOfCountry') AS CE_OUT_OF_COUNTRY,
TRIM(CE.data ->> 'paidDate') AS CE_PAID_DATE,
CE.data ->> 'makeAnApplications' AS CE_MAKE_AN_APPLICATIONS,
TRIM(CE.data ->> 'remissionType') AS ce_remission_type,
TRIM(CE.data ->> 'remissionClaim') AS ce_remission_claim,
TRIM(CE.data ->> 'remissionDecision') AS ce_remission_decision
FROM case_event CE
WHERE CE.case_type_id = 'Asylum'
AND CE.created_date >= (current_date-8 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date
) TO STDOUT WITH CSV HEADER
EOF

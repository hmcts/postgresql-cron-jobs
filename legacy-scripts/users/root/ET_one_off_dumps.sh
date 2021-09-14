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
OUTPUT_FILE_NAME=CCD-corrupt-v2.txt
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
with events as(
SELECT   
  id,
  event_id,
  case_data_id,
  created_date,
  data,
  lag(data) over w as prev_data,
  lag(id) over w as prev_id
FROM
   case_event 
   where case_type_id = 'Benefit'
     and created_date > now() - interval '10 months'
   window w as (partition by case_data_id order by id asc)
)
select 
    case_data.reference,
    events.event_id as event_name,
    key as field_name,
    events.id as event_id,
    events.created_date
  from
    events
      join case_data on case_data.id = events.case_data_id,
    jsonb_each(events.data) data
      right join jsonb_each(events.prev_data) prev_data using(key)
  where 
    (data.value is null or data.value = 'null'::jsonb)
    and not (prev_data.value is null or prev_data.value = 'null'::jsonb)
    and key in (
      'adjournCaseDirectionsDueDate',
      'adjournCaseInterpreterLanguage',
      'adjournCaseNextHearingDateOrPeriod',
      'adjournCaseNextHearingFirstAvailableDateAfterDate',
      'adjournCaseNextHearingFirstAvailableDateAfterPeriod',
      'adjournCaseNextHearingListingDuration',
      'adjournCaseNextHearingListingDurationUnits',
      'adjournCaseNextHearingVenueSelected',
      'adjournCaseTime',
      'appeal',
      'appendix12Doc',
      'benefitCode',
      'bodyContent',
      'clerkAppealSatisfactionText',
      'clerkConfirmationOfMRN',
      'clerkConfirmationOther',
      'clerkDelegatedAuthority',
      'clerkOtherReason',
      'confidentialityRequestAppellantGrantedOrRefused',
      'confidentialityRequestJointPartyGrantedOrRefused',
      'confidentialityRequestOutcomeAppellant',
      'confidentialityRequestOutcomeJointParty',
      'createdInGapsFrom',
      'dateAdded',
      'directionDueDate',
      'documentSentToDwp',
      'doesRegulation35Apply',
      'doesSchedule9Paragraph4Apply',
      'dwpEditedEvidenceBundleDocument',
      'dwpEditedEvidenceReason',
      'dwpEditedEvidenceReasonLabel',
      'dwpEditedResponseDocument',
      'dwpFurtherEvidenceStates',
      'dwpFurtherInfo',
      'dwpOriginatingOffice',
      'dwpPresentingOffice',
      'dwpState',
      'dwpUcbEvidenceDocument',
      'elementsDisputedCare',
      'elementsDisputedChildCare',
      'elementsDisputedChildDisabled',
      'elementsDisputedChildElement',
      'elementsDisputedGeneral',
      'elementsDisputedHousing',
      'elementsDisputedIsDecisionDisputedByOthers',
      'elementsDisputedLimitedWork',
      'elementsDisputedLinkedAppealRef',
      'elementsDisputedSanctions',
      'esaWriteFinalDecisionSchedule3ActivitiesQuestion',
      'extensionNextEventDl',
      'infoRequests',
      'informationFromPartySelected',
      'interlocReferralReason',
      'issueCode',
      'jointParty',
      'jointPartyAddress',
      'jointPartyAddressSameAsAppellant',
      'jointPartyIdentity',
      'jointPartyName',
      'panelDoctorSpecialism',
      'pipWriteFinalDecisionComparedToDWPDailyLivingQuestion',
      'pipWriteFinalDecisionComparedToDWPMobilityQuestion',
      'pipWriteFinalDecisionDailyLivingActivitiesQuestion',
      'pipWriteFinalDecisionMobilityActivitiesQuestion',
      'reasonableAdjustments',
      'reservedToJudge',
      'selectWhoReviewsCase',
      'showDwpReassessAwardPage',
      'showFinalDecisionNoticeSummaryOfOutcomePage',
      'showRegulation29Page',
      'showRip1DocPage',
      'showSchedule3ActivitiesPage',
      'showSchedule7ActivitiesPage',
      'showSchedule8Paragraph4Page',
      'showWorkCapabilityAssessmentPage',
      'signedBy',
      'signedRole',
      'sscsInterlocDecisionDocument',
      'sscsInterlocDirectionDocument',
      'supportGroupOnlyAppeal',
      'tempMediaUrl',
      'tempNoteDetail',
      'ucWriteFinalDecisionSchedule7ActivitiesQuestion',
      'updateNotListableDueDate',
      'updateNotListableWhoReviewsCase',
      'waiverDeclaration',
      'waiverReason',
      'waiverReasonOther',
      'writeFinalDecisionAppellantAttendedQuestion',
      'writeFinalDecisionDisabilityQualifiedPanelMemberName',
      'writeFinalDecisionEndDate',
      'writeFinalDecisionIsDescriptorFlow',
      'writeFinalDecisionOtherPanelMemberName',
      'writeFinalDecisionPresentingOfficerAttendedQuestion'
     ) 
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#psql -U send_letter@rpe-send-letter-service-db-prod -h rpe-send-letter-service-db-prod.postgres.database.azure.com -d send_letter  -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "CCD One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

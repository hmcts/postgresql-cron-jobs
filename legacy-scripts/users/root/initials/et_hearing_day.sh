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
OUTPUT_FILE_NAME=CCD-ETHEARING-DAY-Initial-${RUNTODAY}.csv
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
SELECT EXTRACTION_DATE
, CE_CASE_DATA_ID
, CASE_METADATA_EVENT_ID
, CE_CREATED_DATE
, CE_HEARING_ID
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{id}' AS CE_HEARING_DATE_ID
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,listedDate}' AS CE_HEARING_DATE
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Hearing_status}' AS CE_HEARING_STATUS
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Hearing_Glasgow}' AS CE_HEARING_GLASGOW
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingVenueDay}' AS CE_HEARING_VENUE_DAY
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,attendee_claimant}' AS CE_ATTENDEE_CLAIMANT
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Hearing_part_heard}' AS CE_HEARING_PART_HEARD
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingCaseDisposed}' AS CE_HEARING_CASE_DISPOSED
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,attendee_resp_no_rep}' AS CE_ATTENDEE_RESP_NO_REP
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Hearing_reserved_judgement}' AS CE_HEARING_RESERVED_JUDGMENT
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Hearing_typeReadingDeliberation}' AS CE_HEARING_TYPE_READING_DELIB
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,Postponed_by}' AS CE_POSTPONED_BY
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingTimingStart}' AS CE_HEARING_TIMING_START
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingTimingBreak}' AS CE_HEARING_TIMING_BREAK
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingTimingResume}' AS CE_HEARING_TIMING_RESUME
, jsonb_array_elements(CE_HEARING_DATE_COLL)#>>'{value,hearingTimingFinish}' AS CE_HEARING_TIMING_FINISH
FROM (
  SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
  CE.case_data_id AS CE_CASE_DATA_ID,
  CE.ID as CASE_METADATA_EVENT_ID,
  CE.CREATED_DATE as CE_CREATED_DATE,
  CE.data->'hearingCollection' AS CE_HEARING_COLL,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{id}' AS CE_HEARING_ID,
  jsonb_array_elements(CE.data->'hearingCollection')#>'{value,hearingDateCollection}' AS CE_HEARING_DATE_COLL
  FROM case_event CE
  WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
) a
Where CE_HEARING_COLL is not null
ORDER BY CE_CREATED_DATE
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "ET Hearing Day One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

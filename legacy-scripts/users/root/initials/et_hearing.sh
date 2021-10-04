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
OUTPUT_FILE_NAME=CCD-HEARING-Initial-${RUNTODAY}.csv
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
, CE_HEARING_TYPE
, regexp_replace(CE_HEARING_NOTES, E'[\\n\\r]+', '\\n', 'g' ) AS CE_HEARING_NOTES
, CE_HEARING_VENUE
, CE_HEARING_NUMBER
, CE_HEARING_SIT_ALONE
, CE_HEARING_EST_LENGTH
, CE_HEARING_EST_LENGTH_TYPE
, CE_HEARING_PUBLIC_PRIVATE
, CE_JUDGE_DETAILS
FROM (
  SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
  CE.case_data_id        AS CE_CASE_DATA_ID,
  CE.ID as CASE_METADATA_EVENT_ID,
  CE.CREATED_DATE as CE_CREATED_DATE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{id}' AS CE_HEARING_ID,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_type}' AS CE_HEARING_TYPE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_notes}' AS CE_HEARING_NOTES,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,Hearing_venue}' AS CE_HEARING_VENUE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingNumber}' AS CE_HEARING_NUMBER,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingSitAlone}' AS CE_HEARING_SIT_ALONE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingEstLengthNum}' AS CE_HEARING_EST_LENGTH,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingEstLengthNumType}' AS CE_HEARING_EST_LENGTH_TYPE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,hearingPublicPrivate}' AS CE_HEARING_PUBLIC_PRIVATE,
  jsonb_array_elements(CE.data->'hearingCollection')#>>'{value,judge}' AS CE_JUDGE_DETAILS
  FROM case_event CE
  WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
) a
Where CE_HEARING_ID is not null
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

echo -e "" | mail -s "Hearing One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

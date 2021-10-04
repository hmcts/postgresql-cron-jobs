# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-4894
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=CCD-ETHearing-Weekly_${DEFAULT_DATE}.csv
#TO_ADDRESS=Teodor.Petkovic@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=rordataingress.test@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-ETHearing-Weekly report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-ETHearing-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
AND CE_CREATED_DATE >= (current_date-7 + time '00:00')
AND CE_CREATED_DATE < (current_date + time '00:00')
ORDER BY CE_CREATED_DATE
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-ETHearing-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-ETHearing-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-ETHearing-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD-ETHearing-Weekly Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-ETHearing-Weekly report Complete"

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
OUTPUT_FILE_NAME=CCD-ETJURISDICTION-Initial-${RUNTODAY}.csv
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
SELECT * FROM
(SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
CE.case_data_id        AS CE_CASE_DATA_ID,
CE.ID as CE_ID,
CE.CREATED_DATE as CE_CREATED_DATE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{id}' AS CE_JURISDICTION_ID,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,juridictionCodesList}' AS CE_JURISDICTION_CODE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,judgmentOutcome}' AS CE_JUDGMENT_OUTCOME,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,date_judgment_made}' AS DATE_JUDGMENT_MADE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,liability_optional}' AS LIABILITY_OPTIONAL,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,date_judgment_sent}' AS DATE_JUDJMENT_SENT,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,hearing_number}' AS HEARING_NUMBER
FROM case_event CE
where ce.id = (select max(b.id) from case_event b where b.case_data_id = ce.case_data_id)
AND CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
ORDER BY CE.created_date) a
Where CE_JURISDICTION_ID is not null
)
TO STDOUT with csv header
EOF
)

## Which DB to query? here

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "JURISDICTION One-off dumps complete " -a ${OUTPUT_DIR}/COMPLETE.txt -r $FROM_ADDRESS ${TO_ADDRESS}  


log "One-off dump Complete"

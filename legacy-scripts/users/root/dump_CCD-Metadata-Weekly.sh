#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=METADATA_${DEFAULT_DATE}.csv
TO_ADDRESS=rordataingress.test@hmcts.net
#CC_ADDRESS=Benjamin.Neill@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-Metadata-Weekly Dump report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-Metadata-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
COPY (SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id AS ce_id,
CE.case_data_id AS ce_case_data_id,
CE.created_date AS ce_created_date,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
trim(CE.event_id) AS ce_event_id,
trim(CE.event_name) AS ce_event_name,
trim(CE.state_id) AS ce_state_id,
trim(CE.state_name) AS ce_state_name,
CD.created_date AS cd_created_date,
CD.last_modified AS cd_last_modified,
trim(CD.jurisdiction) AS cd_jurisdiction,
CD.reference AS cd_reference,
trim(CE.user_id)       AS ce_user_id,
trim(CE.user_first_name) AS ce_user_first_name,
trim(CE.user_last_name)  AS ce_user_last_name
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id 
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-Metadata-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-Metadata-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-Metadata-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD Data Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS  ${CC_COMMAND} ${TO_ADDRESS} alliu.balogun@hmcts.net

log "CCD-Metadata-Weekly Dump Complete"

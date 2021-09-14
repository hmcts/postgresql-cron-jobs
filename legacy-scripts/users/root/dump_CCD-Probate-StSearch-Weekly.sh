# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-4894
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=CCD-Probate-StSearch_${DEFAULT_DATE}.csv
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=rordataingress.test@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-Probate-StSearch report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-Probate-StSearch dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
CE.id			AS case_metadata_event_id,
CE.case_data_id		AS ce_case_data_id,
CE.created_date		AS ce_created_date,
trim(CE.case_type_id)	AS ce_case_type_id,
CE.case_type_version	AS ce_case_type_version,
trim(CE.data ->>'applicationType') AS ce_app_type,
trim(CE.data ->>'registryLocation') AS ce_reg_location,
trim(CE.data ->>'expiryDate') AS ce_expiry_date,
trim(CE.data ->>'legacyId') AS ce_leg_record_id,
trim(CE.data ->>'applicationSubmittedDate') AS ce_app_sub_date
FROM case_event CE
WHERE CE.case_type_id = 'StandingSearch'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-Probate-StSearch query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-Probate-StSearch results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
#gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-Probate-StSearch report for ${DEFAULT_DATE}." | mail -s "CCD-Probate-StSearch Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-Probate-StSearch report Complete"

# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-5146
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=CCD-SSCS-Weekly_${DEFAULT_DATE}.csv
TO_ADDRESS=rordataingress.test@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-SSCS-Weekly report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-SSCS-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
trim(CE.data ->> 'caseReference') AS CE_BEN_CASE_REF,
trim(CE.data ->> 'caseCreated') AS CE_CASE_CREATED_DATE,
trim(CE.data -> 'appeal' ->> 'receivedVia') AS CE_RECEIVED_VIA,
trim(CE.data -> 'appeal' ->> 'hearingType') AS CE_HEARING_TYPE,
trim(CE.data -> 'appeal' -> 'rep' ->> 'hasRepresentative') AS CE_HAS_REPR,
trim(CE.data -> 'regionalProcessingCenter' ->> 'name') AS CE_REGIONAL_CENTRE,
trim(CE.data ->> 'outcome') AS CE_CASE_OUTCOME,
trim(CE.data ->> 'caseCode') AS CE_CASE_CODE,
trim(CE.data ->> 'directionType') AS CE_DIRECTION_TYPE,
trim(CE.data ->> 'decisionType') AS CE_DECISION_TYPE
FROM case_event CE
WHERE CE.case_type_id = 'Benefit'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-SSCS-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-SSCS-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-SSCS-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD-SSCS-Weekly Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-SSCS-Weekly report Complete"

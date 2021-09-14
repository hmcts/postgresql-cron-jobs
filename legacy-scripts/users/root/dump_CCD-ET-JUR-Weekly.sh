# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-4894
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=CCD-ET-JUR-Weekly_${DEFAULT_DATE}.csv
#TO_ADDRESS=Teodor.Petkovic@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=rordataingress.test@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-ET-JUR-Weekly report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-ET-JUR-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date) a
Where CE_JURISDICTION_ID is not null
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-ET-JUR-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-ET-JUR-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
#gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-ET-JUR-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD-ET-JUR-Weekly Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-ET-JUR-Weekly report Complete"

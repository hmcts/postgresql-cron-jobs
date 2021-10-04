# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

#YESTERDAY=20190515 
#DEFAULT_DATE=20191231 
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d')
YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=Failed_QA${DEFAULT_DATE}.csv
TO_ADDRESS=Kevin.Bunn@justice.gov.uk
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Wills daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "QA Failed ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT to_char(CAST (ce.created_date AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
 trim(ce.data->>'registryLocation') AS registry,
 cd.reference AS case_number,
 ce.data ->> 'deceasedSurname' AS Deceased_Surname,
 ce.data ->> 'deceasedForenames' AS Deceased_Forename,
 jsonb_array_elements(ce.data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason
 FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE ce.case_type_id = 'GrantOfRepresentation' AND ce.event_id='boFailQA' AND ce.data->>'registryLocation' = 'ctsc'
AND ce.data #>> '{boCaseStopReasonList}' IS NOT NULL
--AND ce.created_date::date between '20200113' and '20200119'  ORDER BY 4 ) to stdout with csv header
AND ce.created_date::date >= '${DAYSAGO}'  ORDER BY 4 ) to stdout with csv header
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccdro@ccd-data-store-performance -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Wills Report on ${DEFAULT_DATE}"

log "Sending email with Wills Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Failed QA" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "Failed QA- Report Complete"

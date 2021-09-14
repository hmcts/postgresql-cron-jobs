# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-6495
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=DocFormats_${DEFAULT_DATE}.csv
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
CC_ADDRESS=dan.thompson@digital.justice.gov.uk 
TO_ADDRESS=andrew.collier@hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Employment CaseTypeID report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "EMPLOYMENT CaseType ID Count Report ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
select case_event.case_type_id, count(distinct(case_data.id)) as cases, count(case_event.id) as case_events
from case_data join case_event on case_data.id = case_event.case_data_id
where case_data.jurisdiction = 'EMPLOYMENT'
group by 1 order by 1) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping EMPLOYMENT CaseType ID Count Report query on ${DEFAULT_DATE}"

echo -e "Hi\nPlease find attached EMPLOYMENT CaseType ID Count Report for ${DEFAULT_DATE}." | mail -s "EMPLOYMENT CaseType ID Count Report " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} alliu.balogun@hmcts.net

log "EMPLOYMENT CaseType ID Count Report report Complete"

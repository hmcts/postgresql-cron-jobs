# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-6584
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=AuditByService_${DEFAULT_DATE}.csv
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
TO_ADDRESS=lawrie.baber-scovell1@hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="File Types report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Audit of Service Report ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT servicename, action, count(id) AS "Number of Documents Accessed" FROM auditentry GROUP BY 1,2 order by 2,3) TO STDOUT WITH CSV HEADER
EOF
)

 psql -h dm-store-postgres-db-prod.postgres.database.azure.com -p 5432 -U evidence@dm-store-postgres-db-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Audit of Service Report query on ${DEFAULT_DATE}"

echo -e "Hi\nPlease find attached Audit of Service Report for ${DEFAULT_DATE}." | mail -s "Audit of Service Report " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} alliu.balogun@hmcts.net

log "Audit of Service Report Complete"

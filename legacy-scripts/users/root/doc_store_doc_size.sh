# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-6495
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=DocSize_${DEFAULT_DATE}.csv
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=lawrie.baber-scovell1@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Doc Size report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Doc Size Report ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT (CASE     WHEN "size" BETWEEN 0             AND 999999         THEN '0-1MB'
                 WHEN "size" BETWEEN 1000000     AND 4999999     THEN '1-5MB'
                 WHEN "size" BETWEEN 5000000     AND 9999999     THEN '5-10MB'
                 WHEN "size" BETWEEN 10000000     AND 24999999     THEN '10-25MB'
                 WHEN "size" BETWEEN 25000000     AND 49999999     THEN '25-50MB'
                 WHEN "size" BETWEEN 50000000     AND 99999999     THEN '50-100MB'
                 WHEN "size" BETWEEN 100000000     AND 249999999     THEN '100-250MB'
                 WHEN "size" >                        250000000     THEN '250MB+'
        END) AS "SIZE RANGE", count( * ) AS "TOTAL"
FROM documentcontentversion
GROUP BY "SIZE RANGE"
ORDER BY max("size") DESC) TO STDOUT WITH CSV HEADER
EOF
)

 psql -h dm-store-postgres-db-prod.postgres.database.azure.com -p 5432 -U evidence@dm-store-postgres-db-prod -d evidence -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Doc Store File Size Report query on ${DEFAULT_DATE}"

echo -e "Hi\nPlease find attached Doc Store File Size Report report for ${DEFAULT_DATE}." | mail -s "Doc Store File Size Report Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} 

log "Doc Store File Size Report report Complete"

#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20190322 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}caveats.csv
TO_ADDRESS=Janet.Dunbar@Justice.gov.uk
CC_ADDRESS=Coral.heal@justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Expiring Caveats daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Expiring Legacy Caveats ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT caveat_number, cav_expiry_date, registry_name FROM caveats_flat WHERE cav_expiry_date = DATE '$YESTERDAY' ORDER BY cav_expiry_date, caveat_number) TO STDOUT WITH CSV HEADER
EOF
)
psql -U probateman_user@probatemandb-postgres-db-prod -h probatemandb-postgres-db-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Expiring Caveats Report on ${DEFAULT_DATE}"

log "Sending email with Expiring Caveats Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Expiring Legacy Caveats" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "Expiring Caveats Report Complete"

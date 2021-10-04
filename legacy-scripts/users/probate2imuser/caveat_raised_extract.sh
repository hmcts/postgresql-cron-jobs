#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20200324 
#YESTERDAY=20200323 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}caveats_raised.csv
TO_ADDRESS=jessica.newton@justice.gov.uk
CC_ADDRESS=james.hellen@justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Caveats Raised Yesterday ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} " | mail -s "Caveats Raised Yesterday ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
COPY (SELECT cd.reference AS ccd_reference, 
ce.created_date AS caveat_raised_date_time, 
CASE WHEN cd.data->>'registryLocation' IS NULL THEN 'NULL'  ELSE trim(cd.data->>'registryLocation')  END AS registryLocation, 
CASE WHEN cd.data->>'paperForm' IS NULL THEN 'NULL'  ELSE trim(cd.data->>'paperForm')  END AS paperForm 
FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id 
--WHERE cd.jurisdiction='PROBATE' AND ce.state_id='CaveatRaised' AND ce.created_date::date between '20200118' and '20200119' 
WHERE cd.jurisdiction='PROBATE' AND ce.state_id='CaveatRaised' AND ce.created_date::date = '$YESTERDAY' 
ORDER BY 1,2) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping  Caveats Raised Report on ${DEFAULT_DATE}"

log "Sending email with Caveats Raised Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Caveats Raised Yesterday" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log " Caveats Raised Report Complete"

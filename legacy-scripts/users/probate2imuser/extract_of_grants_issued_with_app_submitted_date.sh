#!/bin/bash
# vi:syntax=sh
#
# See details here - https://tools.hmcts.net/jira/browse/PRO-5652
# Disabled on 9/1/2020 at Janet Dunbar's request
#
# Alliu Balogun 24/6/2019
#
# 
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20190322 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}extract_of_grants_issued_with_app_submitted_date.csv
TO_ADDRESS=Ronni.Gorham@justice.gov.uk
CC_ADDRESS=lucy.astle-fletcher@Justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
#FAILURE_ADDRESS=dcd-devops-support@hmcts.net
FAILURE_ADDRESS=alliu.balogun@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Extract of grants issued with application submitted date ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Extract of grants issued with application submitted date ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
COPY (SELECT trim(data->>'applicationType') AS grant_applicant_type, trim(data->>'caseType') AS app_case_type, trim(data->>'paperForm') AS paperForm, data->>'applicationSubmittedDate' AS applicationSubmittedDate, trim(data->>'grantIssuedDate') AS grant_issued_date from case_data WHERE case_type_id = 'GrantOfRepresentation' AND data->>'grantIssuedDate' >= '2019-04-01' ORDER BY 4) TO STDOUT WITH CSV HEADER
EOF
)
psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Extract of grants issued with application submitted date on ${DEFAULT_DATE}"

log "Sending email with Extract of grants issued Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Extract of grants issued with application submitted date" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "Extract of grants issued with application submitted date Complete"

#!/bin/bash
# vi:syntax=sh

## Email output of Wills to internal Justice Users
# https://tools.hmcts.net/jira/browse/RDO-3874

# Alliu Balogun - 18/2/2020

# Implement Welsh Service Monitoring - https://tools.hmcts.net/jira/browse/RDO-6424

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

#YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
YESTERDAY=20200214
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20200217 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}_WelshLanguageGrantsIssued.csv
TO_ADDRESS=sean.riley@hmcts.net
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=nico.henderyckx@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="Welsh Language Grants Issued daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
#  echo -e "Hi\n${dump_failed_error} today" | mail -s "Welsh Language Grants Issued ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
 SELECT reference, state, to_char(CAST (data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY')  AS grant_issued_date, data->>'paperForm' AS paperForm, data->>'applicationType' AS  applicationType,created_date, last_modified   FROM case_data  WHERE jurisdiction = 'PROBATE' AND  data->>'languagePreferenceWelsh' = 'Yes' AND created_date::date >= '$YESTERDAY' order by created_date) TO STDOUT with csv header ;
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Welsh Language Grants Issued Report on ${DEFAULT_DATE}"

log "Sending email with Welsh Language Grants Issued Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Weekly Welsh Language Grants Issued" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS} alan.webster@hmcts.net  


log "Welsh Language Grants Issued Report Complete"

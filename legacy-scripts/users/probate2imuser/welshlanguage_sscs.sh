#!/bin/bash
# vi:syntax=sh


# Alliu Balogun - 24/9/2020

# Implement Welsh Service SSCS Monitoring - https://tools.hmcts.net/jira/browse/RDO-8943

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
OUTPUT_FILE_NAME=${DEFAULT_DATE}_WelshLanguageSSCS.txt
TO_ADDRESS=sean.riley@hmcts.net
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=sheila.cleary@Justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="SSCS Welsh Language daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
#  echo -e "Hi\n${dump_failed_error} today" | mail -s "Welsh language SSCS Issued ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}
#AND created_date::date >= '$YESTERDAY' 
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
SELECT cd.reference, ce.created_date AS event_date,cd.last_state_modified_date, ce.state_id, ce.event_name, ce.user_first_name,ce.user_last_name, cd.data->>'languagePreferenceWelsh' AS Welsh_Flag,cd.data->'appeal'->'appellant'->'name'->>'lastName'AS lastname, cd.data->'appeal'->'appellant'->'address'->>'postcode' AS postcode  FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE cd.case_type_id='Benefit' AND jurisdiction='SSCS' AND upper(cd.data->>'languagePreferenceWelsh')='YES' ORDER BY 1,2 desc) TO STDOUT with csv header ;
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Welsh Language SSCS Issued Report on ${DEFAULT_DATE}"

log "Sending email with Welsh Language SSCS Issued Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "SSCS - Weekly Welsh Language Issued" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS}   helen.smith6@justice.gov.uk Rosie.Clarke@HMCTS.NET


log "Welsh Language SSCS Issued Report Complete"

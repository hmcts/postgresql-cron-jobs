#!/bin/bash
# vi:syntax=sh


# Alliu Balogun - 17/7/2020

# Implement Welsh Service Divorce Monitoring - https://tools.hmcts.net/jira/browse/RDO-8193

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
OUTPUT_FILE_NAME=${DEFAULT_DATE}_WelshLanguageDivorce.csv
TO_ADDRESS=sean.riley@hmcts.net
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=nico.henderyckx@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="Divorce Welsh Language daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"
echo ""
#  echo -e "Hi\n${dump_failed_error} today" | mail -s "Welsh language Divorce Issued ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT cd.reference, ce.created_date AS event_date,cd.last_state_modified_date, ce.state_id, ce.event_name, cd.data->>'D8DivorceUnit' AS D8DivorceUnit, cd.data->'D8PetitionerHomeAddress'->>'PostCode' AS D8PetitionerHomeAddress_postcode, ce.user_first_name,ce.user_last_name, cd.data->>'LanguagePreferenceWelsh' AS Welsh_Flag  FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE cd.case_type_id='DIVORCE' AND upper(cd.data->>'LanguagePreferenceWelsh')='YES' ORDER BY 1,2 desc) TO STDOUT with csv header ;
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Welsh Language Divorce Issued Report on ${DEFAULT_DATE}"

log "Sending email with Welsh Language Divorce Issued Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Weekly Welsh Language Divorce Issued" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS}  Isabel.syred@justice.gov.uk 


log "Welsh Language Divorce Issued Report Complete"

# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

#YESTERDAY=20190515 
#DEFAULT_DATE=20191231 
YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=Stops${DEFAULT_DATE}.csv
TO_ADDRESS=Lucy.Astle-fletcher@justice.gov.uk
#TO_ADDRESS=UKHMCTSWillRelease@exelaonline.com
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Wills daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Will extract ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT to_char(CAST (last_modified AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
 trim(data->>'registryLocation') AS registry,
 reference AS case_number,
 CONCAT(data ->> 'deceasedSurname', ' ',data ->> 'deceasedForenames') AS full_name,
 jsonb_array_elements(data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason
 FROM case_data
 WHERE jurisdiction = 'PROBATE' AND state='BOCaseStopped'
AND data #>> '{boCaseStopReasonList}' IS NOT NULL
AND last_modified::date = '${YESTERDAY}'  ORDER BY 3 ) to stdout with csv header;
--AND last_modified::date between '20190326' and '20190520'  ORDER BY 3 ) to stdout with csv header;
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Wills Report on ${DEFAULT_DATE}"

log "Sending email with Wills Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Stops applied to Grants" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} madhu.kumar@justice.gov.uk


log "Wills -Stops to Grants- Report Complete"

# vi:syntax=sh
#
# For details, see
# https://tools.hmcts.net/jira/browse/PRO-5680
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
OUTPUT_FILE_NAME=RegistryGrantManifest${DEFAULT_DATE}.txt
TO_ADDRESS=Lucy.Astle-fletcher@justice.gov.uk
CC_ADDRESS=Coral.heal@justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="Grants Issued Yesterday Extract ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Grants Issued Yesterday Extract ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT
reference AS ccd_reference,
to_char(CAST (data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY') AS grant_issued_date,
trim(data->>'deceasedForenames') AS deceasedForenames,
trim(data->>'deceasedSurname') AS deceasedSurname,
trim(data->>'registryLocation') AS registryLocation
FROM case_data
WHERE jurisdiction='PROBATE' AND (data->>'grantIssuedDate')::date = '$YESTERDAY' ORDER BY 4) to stdout with csv header;
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Grants Issued Yesterday Extract on ${DEFAULT_DATE}"

log "Sending email with Grants Issued Yesterday Extract results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Grants Issued Yesterday Extract" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "Grants Issued Yesterday Extract - Report Complete"

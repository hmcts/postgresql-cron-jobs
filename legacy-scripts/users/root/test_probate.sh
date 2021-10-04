#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
	  echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp/
OUTPUT_FILE_NAME=PROBATE_${DEFAULT_DATE}.csv
TO_ADDRESS=tim.davies@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET
FAILURE_ADDRESS=alliu.balogun@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday Probate Dump report for ${DEFAULT_DATE}"
  local environment=$(getEnvironment)

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} in ${environment}" | mail -s "Probate dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}

function getEnvironment() {
    case $(hostname | awk '{print tolower($0)}') in
    betadeva*)
      ENV=Dev
      ;;
    betadevb*)
      ENV=Test
      ;;
    betademo*)
      ENV=Demo
      ;;
    betapreprod*)
      ENV=PreProd
      ;;
    betaprod*)
      ENV=Production
      ;;
      *)
      log 'Unknown environment' || false
    esac
    echo ${ENV}
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
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
trim(CD.jurisdiction) AS cd_service,
CE.created_date AS ce_created_date,
CD.created_date AS cd_org_created_date,
CD.last_modified AS cd_last_modified_date,
trim(CE.event_id) AS ce_event_id,
trim(CE.event_name) AS ce_event_name,
trim(CE.state_id) AS ce_state_id,
trim(CE.state_name) AS ce_state_name,
trim(CD.state) AS cd_state,
trim(CE.case_type_id) AS ce_case_type_id,
trim(CD.case_type_id) AS cd_case_type_id,
CE.case_type_version AS ce_case_type_version,
CASE WHEN CD.data->>'registryLocation' IS NULL THEN 'OTHER'
ELSE CD.data->>'registryLocation' END AS cd_registry_location
FROM case_data CD, case_event CE
WHERE CD.id=CE.case_data_id 
AND CE.created_date >= (current_date-7 + time '04:00')
AND CE.created_date < (current_date + time '04:00')
AND CD.jurisdiction='PROBATE'
AND CE.id IN (SELECT MAX(CE2.id) FROM case_event CE2 WHERE CE2.case_data_id=CE.case_data_id)
ORDER BY CE.created_date ASC) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-prod -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping query on ${DEFAULT_DATE}"

log "Sending email with probate dump results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "Hi\nPlease find attached Probate report for ${DEFAULT_DATE}." | mail -s "CCD Data Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r "alliu.balogun@hmcts.net " ${CC_COMMAND} ${TO_ADDRESS}

log "Probate Dump Complete"

#!/bin/bash
# vi:syntax=sh

## Email output of Wills to internal Justice Users
# https://tools.hmcts.net/jira/browse/PRO-5115

# Alliu Balogun - 13/8/2019


set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20190322 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}annotation.txt
#TO_ADDRESS=UKHMCTSWillRelease@exelaonline.com
TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
#FAILURE_ADDRESS=dcd-devops-support@hmcts.net
FAILURE_ADDRESS=alliu.balogun@hmcts.net

function errorHandler() {
  local dump_failed_error="Iron Mountain Notations daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Iron Mountain Notations ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
WITH subquery AS (
  SELECT *
  FROM case_data, jsonb_array_elements(data ->'probateDocumentsGenerated') AS dateAdded
     WHERE jurisdiction = 'PROBATE' AND data->>'reissueReasonNotation' != 'duplicate'
--  AND data ->> 'latestGrantReissueDate' = '${YESTERDAY}'
 AND data ->> 'latestGrantReissueDate' between '2019-06-01' and '2019-08-30'
  AND dateAdded -> 'value' ->> 'DocumentType' in ('digitalGrantReissue', 'intestacyGrantReissue', 'admonWillGrantReissue'))
SELECT DISTINCT
  reference AS app_grant_probate_number,
  data ->> 'deceasedForenames' AS estate_forenames,
  data ->> 'deceasedSurname' AS estate_surname,
  to_char(CAST (data ->> 'latestGrantReissueDate' AS DATE), 'DD/MM/YYYY')  AS grant_issued_date,
  511 AS registry_reg_location_code,
  'Principal Registry' AS reg_name,
  to_char(CAST (data ->> 'latestGrantReissueDate' AS DATE), 'DD/MM/YYYY') AS app_event_date,
  CASE WHEN data ->> 'reissueReasonNotation' = 'registrarsOrder' THEN 'Amended and re-issued pursuant to Registrar''s order dated'|| ' ' || (to_char(CAST (data ->> 'reissueDate' AS DATE), 'DD/MM/YYYY')) WHEN  data ->> 'reissueReasonNotation' = 'registrarsDirection' THEN 'Amended and re-issued' || ' ' || (to_char(CAST (data ->> 'reissueDate' AS DATE), 'DD/MM/YYYY')) || ' ' || 'pursuant to Registrar''s Direction 004/17' END AS app_event_text
FROM subquery WHERE case_type_id = 'GrantOfRepresentation'
AND state = 'BOGrantIssued' ORDER BY 2) TO STDOUT ( delimiter(','), header false );
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Iron Mountain Notations Report on ${DEFAULT_DATE}"

log "Sending email with Iron Mountain Notations Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "Iron Mountain Notations" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS  ${TO_ADDRESS} 


log "Iron Mountain Notations Report Complete"

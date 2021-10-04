#!/bin/bash
# vi:syntax=sh

## Email output of Wills to internal Justice Users
# https://tools.hmcts.net/jira/browse/RDO-3874

# Alliu Balogun - 18/4/2019

# Added RegistryLocation - 18/7/2019 - https://tools.hmcts.net/jira/browse/RDO-4515

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y-%m-%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20200217 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}wills.txt
TO_ADDRESS=#UKHMCTSWillRelease@exelaonline.com
#TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=Janet.dunbar@justice.gov.uk
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@hmcts.net

function errorHandler() {
  local dump_failed_error="Exela daily extract for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "UK HMCTS Will Release ${DEFAULT_DATE} failed " -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
  FROM case_data, jsonb_array_elements(data ->'probateDocumentsGenerated') AS dateAdded,
    jsonb_array_elements(data -> 'scannedDocuments') AS docs
  WHERE jurisdiction = 'PROBATE' AND LOWER(docs -> 'value' ->> 'subtype') = 'will'
  AND data ->> 'grantIssuedDate' = '${YESTERDAY}'
  --AND data ->> 'grantIssuedDate' between '2020-02-17' and '2020-02-02' 
  AND dateAdded -> 'value' ->> 'DocumentType' in ('digitalGrant', 'admonWillGrant', 'intestacyGrant'))
  
SELECT DISTINCT
  reference AS ccd_case_number,
  CONCAT(data ->> 'deceasedSurname', ' ',data ->> 'deceasedForenames') AS full_name,
  to_char(CAST (data ->> 'deceasedDateOfBirth' AS DATE), 'DD/MM/YYYY')  AS dob,
  lower(opt -> 'value' ->> 'controlNumber') AS will_reference_number,
  to_char(CAST (data ->> 'grantIssuedDate' AS DATE), 'DD/MM/YYYY')  AS grant_issue_date,
  CASE WHEN data->>'registryLocation' IS NULL THEN 'NULL'  ELSE trim(data->>'registryLocation')  END AS registryLocation
FROM subquery, jsonb_array_elements(data #> '{scannedDocuments}') WITH ORDINALITY arr (opt, ord)
WHERE lower(opt -> 'value' ->> 'subtype') = 'will'
AND case_type_id = 'GrantOfRepresentation'
AND state = 'BOGrantIssued' ORDER BY 2) TO STDOUT ( delimiter(','), header false );
EOF
)

psql -U ccdro@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Exela Report on ${DEFAULT_DATE}"

log "Sending email with Exela Report results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "UK HMCTS Will Release" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${CC_COMMAND} ${TO_ADDRESS} Madhu.Kumar@justice.gov.uk 


log "Exela Report Complete"

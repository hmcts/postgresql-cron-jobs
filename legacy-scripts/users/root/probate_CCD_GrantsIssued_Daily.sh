# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=PB_CCD_GRANTSISSUED${DEFAULT_DATE}.csv
TO_ADDRESS=Teodor.Petkovic@hmcts.net
CC_ADDRESS=Benjamin.Neill@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
#TO_ADDRESS=rordataingress.test@hmcts.net
#CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Probate_CCD_GrantsIssued_Daily report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "Probate_CCD_GrantsIssued_Daily dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
COPY (WITH subquery AS (
  SELECT *
  FROM case_data, jsonb_array_elements(data ->'probateDocumentsGenerated') AS dateAdded,
    jsonb_array_elements(data -> 'scannedDocuments') AS docs
  WHERE LOWER(docs -> 'value' ->> 'subtype') = 'will'
  AND data ->> 'grantIssuedDate' >= '20190407'
  AND dateAdded -> 'value' ->> 'DocumentType' in ('"digitalGrant"', '"admonWillGrant"', '"intestacyGrant"')
  

SELECT DISTINCT
  reference AS ccd_case_number,
  data ->> 'deceasedSurname' AS deceased_surname,
  lower(opt -> 'value' ->> 'controlNumber') AS will_reference_number
FROM subquery, jsonb_array_elements(data #> '{scannedDocuments}') WITH ORDINALITY arr (opt, ord)
WHERE lower(opt -> 'value' ->> 'subtype') = 'will'
AND jurisdiction = 'PROBATE'
AND case_type_id = 'GrantOfRepresentation'
AND state = 'BOGrantIssued') TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-prod -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping Probate_CCD_GrantsIssued_Daily query on ${DEFAULT_DATE}"

##log "GZIP & Sending email with Probate_CCD_GrantsIssued_Daily results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
##gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached Probate_CCD_GrantsIssued_Daily report for ${DEFAULT_DATE}." | mail -s "UK HMCTS Will Release" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS  ${CC_COMMAND} ${TO_ADDRESS} teodor.petkovic@hmcts.net

log "Probate_CCD_GrantsIssued_Daily report Complete"

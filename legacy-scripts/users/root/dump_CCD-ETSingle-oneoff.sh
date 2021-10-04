# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-4894
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/backups/dumps
OUTPUT_FILE_NAME=CCD-ETSingle-Initials_v6.csv
#TO_ADDRESS=Teodor.Petkovic@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=rordataingress.test@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-ETSingle-Weekly report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-ETSingle-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
CE.id                  AS CASE_METADATA_EVENT_ID,
CE.case_data_id        AS CE_CASE_DATA_ID,
CE.created_date        AS CE_CREATED_DATE,
trim(CE.case_type_id)  AS CE_CASE_TYPE_ID,
CE.case_type_version   AS CE_CASE_TYPE_VERSION,
trim(CE.data ->>'caseType') AS ce_case_type,
trim(CE.data ->>'receiptDate') AS ce_receipt_date,
trim(CE.data ->>'positionType') AS ce_position_type,
trim(CE.data ->>'multipleReference') AS ce_multiple_ref,
trim(CE.data ->>'ethosCaseReference') AS ce_ethos_case_ref,
trim(CE.data ->>'managingOffice') AS ce_managing_office,
trim(CE.data ->>'claimant_TypeOfClaimant') AS ce_claimant_type,
trim(CE.data ->>'claimantRepresentedQuestion') AS ce_claimant_represented,
trim(CE.data ->>'jurCodesCollection') AS ce_jurisdictions,
trim(CE.data ->>'leadClaimant') AS ce_lead_claimant,
trim(CE.data ->'preAcceptCase' ->>'dateAccepted') AS ce_date_accepted,
trim(CE.data ->>'judgementCollection') AS ce_judgment_collection,
trim(CE.data ->>'hearingCollection') AS ce_hearing_collection,
TRIM(ce.data ->> 'conciliationTrack') AS ce_conciliation_track
FROM case_event CE
WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
ORDER BY CE.created_date DESC
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-ETSingle-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-ETSingle-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

#echo -e "Hi\nPlease find attached CCD-ETSingle-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD-ETSingle-Weekly Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-ETSingle-Weekly report Complete"

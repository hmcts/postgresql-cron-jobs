# vi:syntax=sh

# https://tools.hmcts.net/jira/browse/RDO-6501
set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

DEFAULT_DATE=$(date +%F) ##--date '-1 days')
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=CCD-SSCS_ExceptionRecord-Weekly_${DEFAULT_DATE}.csv
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
TO_ADDRESS=rordataingress.test@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
#FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=dcd-devops-support@HMCTS.NET

function errorHandler() {
  local dump_failed_error="Monday CCD-SSCS_ExceptionRecord-Weekly report for ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "CCD-SSCS_ExceptionRecord-Weekly dump ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
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
CE.id			AS case_metadata_event_id,
CE.case_data_id		AS ce_case_data_id,
CE.created_date		AS ce_created_date,
trim(CE.case_type_id)	AS ce_case_type_id,
CE.case_type_version	AS ce_case_type_version,
trim(CE.data ->> 'journeyClassification') AS CE_JOURNEYCLASSIFICATION,
trim(CE.data ->> 'deliveryDate') AS CE_DELIVERYDATE,
trim(CE.data ->> 'openingDate') AS CE_OPENINGDATE,
trim(CE.data ->> 'attachToCaseReference') AS CE_ATTACHTOCASEREFERENCE,
trim(CE.data ->> 'caseReference') AS CE_CASEREFERENCE,
trim(CE.data ->> 'state') AS CE_STATE,
trim(CE.data ->> 'formType') AS CE_FORMTYPE,
trim(CE.data ->> 'envelopeId') AS CE_ENVELOPEID,
trim(CE.data ->> 'awaitingPaymentDCNProcessing') AS CE_AWAITINGPAYMENTDCNPROCSSNG,
trim(CE.data ->> 'containsPayments') AS CE_CONTAINSPAYMENTS,
trim(CE.data ->> 'envelopeCaseReference') AS CE_ENVELOPECASEREFERENCE,
trim(CE.data ->> 'envelopeLegacyCaseReference') AS CE_ENVELOPELEGACYCASEREF
FROM case_event CE
WHERE CE.case_type_id = 'SSCS_ExceptionRecord'
AND ce.created_date >= (current_date-7 + time '00:00')
AND ce.created_date < (current_date + time '00:00')
ORDER BY CE.created_date
) TO STDOUT WITH CSV HEADER
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccd@ccd-data-store-performance -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

log "Finished dumping CCD-SSCS_ExceptionRecord-Weekly query on ${DEFAULT_DATE}"

log "GZIP & Sending email with CCD-SSCS_ExceptionRecord-Weekly results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

## gzip file before sending
gzip -9 ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

echo -e "Hi\nPlease find attached CCD-SSCS_ExceptionRecord-Weekly report for ${DEFAULT_DATE}." | mail -s "CCD-SSCS_ExceptionRecord-Weekly Reporting" -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}.gz -r $FROM_ADDRESS ${TO_ADDRESS} 

log "CCD-SSCS_ExceptionRecord-Weekly report Complete"

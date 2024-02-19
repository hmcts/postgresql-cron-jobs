#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='"DTS Platform Operations SC@rd-professional-api-postgres-db-v11-prod'
AZURE_HOSTNAME='rd-professional-api-postgres-db-v11-prod.postgres.database.azure.com'
AZURE_DB='dbrefdata'
SUBJECT='REF-DATA-ORG-ATTRIBUTES Monthly Report'
TO_ADDRESS='raj.katla1@hmcts.net'
CC_ADDRESS='raj.katla1@hmcts.net'
DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_DIR=/tmp
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "select md5(a.name) as encrypted_org_name, a.org_type, b.key, translate(b.value,'1234567890','**********') as value from dbrefdata.organisation a, dbrefdata.org_attributes b where a.id = b.organisation_id;"  >> ${ATTACHMENT}

echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo ""  >> ${ATTACHMENT}
echo "END Count ====== "  >>  ${ATTACHMENT}


log "Finished dumping Report on ${DEFAULT_DATE}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"

filesize=$(wc -c ${ATTACHMENT} | awk '{print $1}')
if [[ $filesize -gt 1000000 ]]
then
  gzip ${ATTACHMENT}
  ATTACHMENT=${ATTACHMENT}.gz
fi
echo ${ATTACHMENT}

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"
rm ${ATTACHMENT}
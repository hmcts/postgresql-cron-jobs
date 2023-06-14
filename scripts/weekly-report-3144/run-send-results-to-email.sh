#!/bin/bash
set -eu

source 'function-declarations.sh'

if ! [[ -e "${ATTACHMENT}" ]];
then
    log "There was an error reading the file created in the previous step."
    exit 1
fi

SUBJECT=""

FILE_SIZE=$(stat -c %s "${ATTACHMENT}")

if [[ $FILE_SIZE -gt 9000000 ]]
then
  az storage blob upload --account-name "timdaexedata"  --account-key "${STORAGE_KEY}"  --container-name "${CONTAINER_NAME}"  --name "${ATTACHMENT}" --file "${ATTACHMENT}"
  log "upload file to storage account"
else
  swaks -f ${FROM_ADDRESS} -t ${TO_ADDRESS},${CC_ADDRESS} --server smtp.sendgrid.net:587 --auth PLAIN -au apikey -ap ${SENDGRID_APIKEY} -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from me"
  log "email sent"
fi
rm ${ATTACHMENT}

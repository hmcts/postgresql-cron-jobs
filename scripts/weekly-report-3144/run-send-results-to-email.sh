source './run-email-report.sh'
source './run-sort-csv-by-date.sh'

# Send the results to an email address
FROM_ADDRESS=""
TO_ADDRESS=""
CC_ADDRESS=""
SUBJECT=""

filesize=$(wc -c ${ATTACHMENT} | awk '{print $1}')
echo "${ATTACHMENT} is $filesize bytes in size"
if [[ $filesize -gt 9000000 ]]
then
  az storage blob upload --account-name "timdaexedata"  --account-key "$STORAGE_KEY"  --container-name "${CONTAINER_NAME}"  --name "${OUTPUT_FILE_NAME}" --file "${ATTACHMENT}"
  printf "upload file to storage account"
else
  swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587 --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from me"
  printf "email sent"
fi

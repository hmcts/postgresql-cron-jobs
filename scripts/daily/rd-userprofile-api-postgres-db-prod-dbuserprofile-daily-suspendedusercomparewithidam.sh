#!/bin/bash
set -fex

# Colour macros
Col_Off='\033[0m'       # Text Reset
Col_Red='\033[0;31m'          # Red
Col_Grn='\033[0;32m'        # Green

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='DTS JIT Access rd DB Reader SC'
AZURE_HOSTNAME='rd-user-profile-api-postgres-db-v16-prod.postgres.database.azure.com'
AZURE_DB='dbuserprofile'
ALL_USERS_FLAG=${ALL_USERS_FLAG}
OAUTH2_CLIENT_ID='rd-professional-api'

SUBJECT='SuspendedUserStatus-Report'
TO_ADDRESS='sabina.sharangdhar@hmcts.net'
CC_ADDRESS='sabina.sharangdhar@hmcts.net'
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)

OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
USERIDAMS='SUSPENDED_USERS.txt'


function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo " =====  Call User Profile table and select suspended users ===== "
echo "ALL_USERS_FLAG $ALL_USERS_FLAG"
# pick suspended users from user profile in the last 2 weeks and write them to a file
if [ $ALL_USERS_FLAG -ne 0 ]
then
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' and last_updated >= NOW() - INTERVAL '14 DAYS';" >> ${USERIDAMS}
 else
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB}  -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED';" >> ${USERIDAMS}
fi
# generating Bearer token to connect to idam
TOKEN_CMD=$(curl -X POST 'https://idam-api.platform.hmcts.net/o/token?grant_type=password&username=admin.refdata@hmcts.net&password='${SYSPASS}'&client_secret='${OAUTH2_CLIENT_SECRET}'&scope=openid%20profile%20roles%20manage-user%20create-user%20search-user&client_id=rd-professional-api' -H Content-Length:0 -H Host:idam-api.platform.hmcts.net -H 'accept: */*' -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded)
TOKEN=$(echo ${TOKEN_CMD} | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '"' )

# iterate file of suspended users
tables=()
while read -r line; do
  tables+=("$line")
done < SUSPENDED_USERS.txt

# for each suspended user from user profile make a call to idam to check if the user exists
for table in ${tables[@]}; do
CMD=$(curl -X GET 'https://idam-api.platform.hmcts.net/api/v1/users/'$table'' -H Authorization:'Bearer '${TOKEN}  -H 'accept: */*' )
RESULT=$(echo ${CMD} | cut -d',' -f 5 | cut -d':' -f 2)
# if user found on idam then print the user and the status on idam
TRUE="true"
if [[ -z "$(echo ${RESULT})" ]];
then
    echo -e "$table" "  :   " "USER NOT IN IDAM" >> ${ATTACHMENT}
else
  if [ "$RESULT" == "$TRUE" ]; then
        echo -e "$table" "  :   " "ACTIVE" >> ${ATTACHMENT}
    else
       echo -e "$table" "  :   " "INACTIVE" >> ${ATTACHMENT}
  fi
fi
done

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"

rm ${USERIDAMS}
rm ${ATTACHMENT}
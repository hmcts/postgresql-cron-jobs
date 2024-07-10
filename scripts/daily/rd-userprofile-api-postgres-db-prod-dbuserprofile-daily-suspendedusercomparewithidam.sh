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
AZURE_DB_USERNAME='pgadmin'
AZURE_HOSTNAME='rd-user-profile-api-postgres-db-v16-aat.postgres.database.azure.com'
AZURE_DB='dbuserprofile'

OAUTH2_CLIENT_SECRET=${OAUTH2_CLIENT_SECRET}
idam_rd_system_user=${USERNAME}
idam_rd_system_pass=${SYSPASS}

SUBJECT='USER_PROFILE_DATA-DB Daily Report'
TO_ADDRESS='sabina.sharangdhar@hmcts.net'
CC_ADDRESS='sabina.sharangdhar@hmcts.net'
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)

OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=suspendedUsersNotFoundOnIdam.csv
OUTPUT_FILE_NAME1=suspendedUsersFoundOnIdam.csv
SUSPENDED_USERS_FOUND=${OUTPUT_DIR}/${OUTPUT_FILE_NAME1}
SUSPENDED_USERS_NOT_FOUND=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
USERIDAMS='SUSPENDED_USERIDAMS.txt'

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
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' and last_updated >= NOW() - INTERVAL '14 DAYS' LIMIT 4;" >> ${USERIDAMS}
 else
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB}  -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' LIMIT 4;" >> ${USERIDAMS}
fi

echo " =====  Generate Bearer token to call IDAM api ===== "
echo ${USERIDAMS}
# generating Bearer token to connect to idam
TOKEN_CMD=$(curl -X POST 'https://idam-api.aat.platform.hmcts.net/o/token?grant_type=password&username='${idam_rd_system_user}'&password='${idam_rd_system_pass}'&client_secret='${OAUTH2_CLIENT_SECRET}'&client_id=rd-professional-api&scope=openid' -H Content-Length:0 -H Host:idam-api.platform.hmcts.net -H 'accept: */*' -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded)
TOKEN=$(echo ${TOKEN_CMD} | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '"' )

# iterate file of suspended users
users=()
while read -r line; do
  users+=("$line")
done < SUSPENDED_USERIDAMS.txt

echo " =====  Call IDAM api to check if suspended users exist===== "

# for each suspended user from user profile make a call to idam to check if the user exists
for user in ${users[@]}; do
cmd=$(curl -X GET 'https://idam-testing-support-api.aat.platform.hmcts.net/test/idam/users/'$user'' -H Authorization:'Bearer '${TOKEN}  -H 'accept: */*' )

# if user found on idam then print the user and the status on idam
if [ -z $(echo ${cmd}) ];
  then
  $user >> ${SUSPENDED_USERS_NOT_FOUND}
  user_count=$(echo ${cmd}  | tee ${SUSPENDED_USERS_NOT_FOUND})
  echo -e "${Col_Grn} Suspended user in User profile not found on IDAM $user ${user_count} ${Col_Off}"
else
  user_count=$( ${CMD}  | tee ${SUSPENDED_USERS_FOUND})
  echo -e "${Col_Red} IDAm IDs found on IDMA database and suspended in UserProfile $user  ${user_count} ${Col_Off}"
fi
done

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${SUSPENDED_USERS_NOT_FOUND} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"

rm ${USERIDAMS}
rm ${SUSPENDED_USERS_NOT_FOUND}
rm ${SUSPENDED_USERS_FOUND}
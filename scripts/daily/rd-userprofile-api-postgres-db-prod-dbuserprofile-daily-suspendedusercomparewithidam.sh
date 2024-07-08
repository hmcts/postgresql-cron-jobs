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
AZURE_HOSTNAME='rd-user-profile-api-postgres-db-v16-prod.postgres.database.azure.com'
AZURE_DB='dbuserprofile'
#idam_rd_system_user='admin.refdata@hmcts.net'
#idam_rd_system_user='prd.demo.cgi4@hmcts.net'
#idam_rd_system_user_password='Password123'
#idam_rd_system_user_password='y8jt2nZefX9G'
OAUTH2_CLIENT_ID='rd-professional-api'
#OAUTH2_CLIENT_SECRET='a20c3cf7-1fb4-4bcf-89ec-963c05a13f71'
#PGPASSWORD='jyS-DDIhqfaBQj7kBWAQ'

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

# generating Bearer token to connect to idam
TOKEN_CMD=$(curl -X POST 'https://idam-api.platform.hmcts.net/o/token?grant_type=password&username='${idam_rd_system_user}'&password='${idam_rd_system_user_password}'&client_secret='${OAUTH2_CLIENT_SECRET}'&client_id='${OAUTH2_CLIENT_ID}'&scope=openid' -H Content-Length:0 -H Host:idam-api.aat.platform.hmcts.net -H 'accept: */*' -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded)
TOKEN=$(echo ${TOKEN_CMD} | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '"' )

# iterate file of suspended users
tables=()
while read -r line; do
  tables+=("$line")
done < SUSPENDED_USERIDAMS.txt

# for each suspended user from user profile make a call to idam to check if the user exists
for table in ${tables[@]}; do
cmd=$(curl -X GET 'https://idam-api.platform.hmcts.net/api/v1/users/'$table'' -H Authorization:'Bearer '${TOKEN}  -H 'accept: */*' )

# if user found on idam then print the user and the status on idam
if [ -z $(echo ${cmd}) ];
  then
  $table >> ${SUSPENDED_USERS_NOT_FOUND}
  user_count=$(echo ${cmd}  | tee ${SUSPENDED_USERS_NOT_FOUND})
  echo -e "${Col_Grn} Suspended user in User profile not found on IDAM $table ${user_count} ${Col_Off}"
else
  user_count=$( ${CMD}  | tee ${SUSPENDED_USERS_FOUND})
  echo -e "${Col_Red} IDAm IDs found on IDMA database and suspended in UserProfile $table  ${user_count} ${Col_Off}"
fi
done

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"

rm ${USERIDAMS}
rm ${SUSPENDED_USERS_NOT_FOUND}
rm ${SUSPENDED_USERS_FOUND}
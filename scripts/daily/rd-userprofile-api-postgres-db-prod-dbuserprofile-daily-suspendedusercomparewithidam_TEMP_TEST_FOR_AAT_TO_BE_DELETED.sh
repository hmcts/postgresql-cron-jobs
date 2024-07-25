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
USERNAME=${USERNAME}
SYSPASS=${SYSPASS}
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
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB}  -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' Limit 1;" >> ${USERIDAMS}
fi


# iterate file of suspended users
tables=()
while read -r line; do
  tables+=("$line")
done < SUSPENDED_USERS.txt

# for each suspended user from user profile make a call to idam to check if the user exists
echo -e "IDAM IDS                                                                               " "  :   " "STATUS ON IDAM" >> ${ATTACHMENT}
echo -e "  " "      " "  " >> ${ATTACHMENT}

# generating Bearer token to connect to idam

TOKEN_CMD=$(curl -X POST 'https://idam-api.aat.platform.hmcts.net/o/token?grant_type=password&username='${USERNAME}'&password='${SYSPASS}'&client_secret='${OAUTH2_CLIENT_SECRET}'&scope=openid%20profile%20roles%20manage-user%20create-user%20search-user&client_id=rd-professional-api' -H Content-Length:0 -H Host:idam-api.aat.platform.hmcts.net -H 'accept: */*' -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded)
TOKEN=$(echo ${TOKEN_CMD} | cut -d':' -f 2 | cut -d',' -f 1 | tr -d '"' )


for table in ${tables[@]}; do
CMD=$(curl -X GET 'https://idam-api.aat.platform.hmcts.net/api/v1/users/'$table'' -H Authorization:'Bearer 'eyJ0eXAiOiJKV1QiLCJraWQiOiIxZXIwV1J3Z0lPVEFGb2pFNHJDL2ZiZUt1M0k9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJhZG1pbi5yZWZkYXRhQGhtY3RzLm5ldCIsImN0cyI6Ik9BVVRIMl9TVEFURUxFU1NfR1JBTlQiLCJhdXRoX2xldmVsIjowLCJhdWRpdFRyYWNraW5nSWQiOiJlM2RkZjI0ZS1kYWJmLTQ4NWQtYWQ2ZC0wODYzNGI3NDM1Y2MtNjE2MDcxNDAiLCJzdWJuYW1lIjoiYWRtaW4ucmVmZGF0YUBobWN0cy5uZXQiLCJpc3MiOiJodHRwczovL2Zvcmdlcm9jay1hbS5zZXJ2aWNlLmNvcmUtY29tcHV0ZS1pZGFtLWFhdDIuaW50ZXJuYWw6ODQ0My9vcGVuYW0vb2F1dGgyL3JlYWxtcy9yb290L3JlYWxtcy9obWN0cyIsInRva2VuTmFtZSI6ImFjY2Vzc190b2tlbiIsInRva2VuX3R5cGUiOiJCZWFyZXIiLCJhdXRoR3JhbnRJZCI6ImJpZ0N6NVlrY1Eta2ZYQUtYUVB0Y1BNRDVEayIsImF1ZCI6InJkLXByb2Zlc3Npb25hbC1hcGkiLCJuYmYiOjE3MjE5Mjg1MTgsImdyYW50X3R5cGUiOiJwYXNzd29yZCIsInNjb3BlIjpbIm9wZW5pZCIsInByb2ZpbGUiLCJyb2xlcyIsImNyZWF0ZS11c2VyIiwibWFuYWdlLXVzZXIiLCJzZWFyY2gtdXNlciJdLCJhdXRoX3RpbWUiOjE3MjE5Mjg1MTgsInJlYWxtIjoiL2htY3RzIiwiZXhwIjoxNzIxOTU3MzE4LCJpYXQiOjE3MjE5Mjg1MTgsImV4cGlyZXNfaW4iOjI4ODAwLCJqdGkiOiJvdzJJcnNjU3pRMXZjLUJpYWhwckZta1M4TUUifQ.S0PL3bKTedio9KfMkOzVrtD_c983wUV9lpJzh0EIzoMAa8qMLlaDGueDhnmt4nV6F3LfFiOnhQLDW9m087jQzqvhbzjYb6TxeEHqrUwmjgBtAuh-_3iNVtRj-6BjK54GPiuBCWX6k_G2yMDGSOo3DbldQO8nI8fhqyaJ0AnE8WHZ8KQbcJ6sFFZzBpTrUZD-q4ABo3Ki6uD5DE6_XwwIciG3B8fhKU_eb1snJDyAPr1uZ00_ac3h9wAfsg-MAebCLDOippVGhE0x6stOD-gLn5sztKAzlnlT-GJuxRTbOGxM549k42Xo5Kl_3voL5Okz4jMWNb48_f_jMtQh3x5TLg  -H 'accept: */*' )
RESULT=$(echo ${CMD} | cut -d',' -f 5 | cut -d':' -f 2)
# if user found on idam then print the user and the status on idam
TRUE="true"
if [[ -z "$(echo ${RESULT})" ]];
then
    echo -e "$table" "  :   " "USER NOT IN IDAM" >> ${ATTACHMENT}
    echo -e "${Col_Red} Suspended user in User profile not found on IDAM $table ${user_count} ${Col_Off}"
else
  echo "users present on idam"
  if [ "$RESULT" == "$TRUE" ]; then
        echo -e "$table" "  :   " "ACTIVE" >> ${ATTACHMENT}
       echo -e "${Col_Grn} USER SUSPENDED IN BOTH IDAM and USERPROFILE :  $table  ${RESULT} ${Col_Off}"
    else
       echo -e "$table" "  :   " "INACTIVE" >> ${ATTACHMENT}
       echo -e "${Col_Grn} USER SUSPENDED IN USERPROFILE BUT IS ACTIVE ON IDAM : $table  ${RESULT} ${Col_Off}"

  fi
fi
done

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached report from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"

rm ${USERIDAMS}
rm ${ATTACHMENT}
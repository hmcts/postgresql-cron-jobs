#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='pgadmin'
AZURE_HOSTNAME='rd-user-profile-api-postgres-db-v16-aat.postgres.database.azure.com'
AZURE_DB='dbuserprofile'

SUBJECT='USER_PROFILE_DATA-DB Daily Report'
TO_ADDRESS='sabina.sharangdhar@hmcts.net'
CC_ADDRESS='sabina.sharangdhar@hmcts.net'
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)

OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
USERPROFILEIDS=${OUTPUT_DIR}/"USERPROFILEIDS"


SCOPE="openid\ profile\ roles\ manage-user\ create-user\ search-user"

FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_FILE_NAME}
USERIDAMS='SUSPENDED_USERIDAMS.csv'

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo " =====  Call User Profile table and select suspended users ===== "

# pick suspended users from user profile in the last 2 weeks and write them to a file
if [ $ALL_USERS_FLAG -ne 0 ]
then
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' and last_updated >= NOW() - INTERVAL '14 DAYS' LIMIT 5;" >> ${USERIDAMS}
 else
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} password="jyS-DDIhqfaBQj7kBWAQ" -c "SELECT idam_id FROM dbuserprofile.user_profile u where idam_status ='SUSPENDED' LIMIT 5;" >> ${USERIDAMS}
fi

# iterate file of suspended users
while read -r line; do
  tables+=("$line")
done < ${USERIDAMS}

# generating Bearer token to connect to idam
HEADERS='-H Content-Length:0 -H Host:idam-api.aat.platform.hmcts.net -H Accept:*/* -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded'
TOKEN_CMD=$ CURL -X -s POST 'https://idam-api.aat.platform.hmcts.net/o/token?grant_type=password&username='$idam-rd-system-user'&password='$idam-rd-system-user-password'&client_id='$OAUTH2-CLIENT-ID'&scope='$SCOPE'&client_secret='$OAUTH2-CLIENT-SECRET $HEADERS
echo "TOKEN :"$TOKEN_CMD

# for each suspended user from user profile make a call to idam to check if the user exists
tables=()
for table in ${tables[@]}; do
echo "helolo"
cmd1=$(curl -X GET 'https://idam-testing-support-api.aat.platform.hmcts.net/test/idam/users/' + $table  -H 'accept: */*' -H 'Authorization:Bearer eyJ0eXAiOiJKV1QiLCJraWQiOiIxZXIwV1J3Z0lPVEFGb2pFNHJDL2ZiZUt1M0k9IiwiYWxnIjoiUlMyNTYifQ.eyJzdWIiOiJ1cC5kZW1vLmNnaUBobWN0cy5uZXQiLCJjdHMiOiJPQVVUSDJfU1RBVEVMRVNTX0dSQU5UIiwiYXV0aF9sZXZlbCI6MCwiYXVkaXRUcmFja2luZ0lkIjoiNTg0Y2IxYjUtMjExMi00Mjc3LWJiNTUtNWFhMzM3NmI0NjEzLTEyNjY0MzEiLCJzdWJuYW1lIjoidXAuZGVtby5jZ2lAaG1jdHMubmV0IiwiaXNzIjoiaHR0cHM6Ly9mb3JnZXJvY2stYW0uc2VydmljZS5jb3JlLWNvbXB1dGUtaWRhbS1hYXQyLmludGVybmFsOjg0NDMvb3BlbmFtL29hdXRoMi9yZWFsbXMvcm9vdC9yZWFsbXMvaG1jdHMiLCJ0b2tlbk5hbWUiOiJhY2Nlc3NfdG9rZW4iLCJ0b2tlbl90eXBlIjoiQmVhcmVyIiwiYXV0aEdyYW50SWQiOiJqd0pKUlBXS0tEM2otbWdmaUJISmVYQUJTMUEiLCJhdWQiOiJyZC1wcm9mZXNzaW9uYWwtYXBpIiwibmJmIjoxNzE5NTA2MTczLCJncmFudF90eXBlIjoicGFzc3dvcmQiLCJzY29wZSI6WyJvcGVuaWQiLCJwcm9maWxlIiwicm9sZXMiLCJjcmVhdGUtdXNlciIsIm1hbmFnZS11c2VyIiwic2VhcmNoLXVzZXIiXSwiYXV0aF90aW1lIjoxNzE5NTA2MTczLCJyZWFsbSI6Ii9obWN0cyIsImV4cCI6MTcxOTUzNDk3MywiaWF0IjoxNzE5NTA2MTczLCJleHBpcmVzX2luIjoyODgwMCwianRpIjoieVNvRHBZZW5EY0IwT0g2RkJxeElOUm9PZHFRIn0.sn2OeWfWpaXcT_nuMmri9a3Oj7zrSXP-YrxbdOPvKyMcQqoRzfpENYzT6_qjcyPzp8ds5P2hFe2JaNYs6Rj7R5Zq1Wiw5LdyITw0IhuLUjvpuabU3fYh4frttnXSddTEBBtOXLq7jHQAKJzwBuRgoJVJlKVLEw7XjwkZ3L4-sl7oNp0Q-TninQJGaRQO4lqLwLE7v7YkdnrMZUytJ-VNpv7ULhNJr1HYfh6OyNooXz5EbRFiWh-DHdTrh3lgB1KTabqpMNm2KU3ptxAwGdkjEZ3bV6wv2jdMw5fDWiqC_txbgl14tVEu-6xG-WGnv72HqLW-0bxqJMBPV-AiC8hs9Q')
idam_entry_count=$( ${cmd1}  | tee idam_entries.txt)
# if user found on idam then print the user and the status on idam
if [ $idam_entry_count -ne 0 ]
  then
    echo -e "${Col_Grn} Suspended user in User profile found on IDAM $table ${Col_Off}"
    echo "idam_entry_count:  $db1_entry_count  and userprofile idam : $table"
  else
    echo -e "${Col_Red}Suspended user in User profile not found on IDAM $table ${Col_Off}"
  fi
done
rm ${USERIDAMS}
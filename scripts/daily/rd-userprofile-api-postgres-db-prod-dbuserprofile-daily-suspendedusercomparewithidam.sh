#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='pgadmin'
AZURE_HOSTNAME='rd-user-profile-api-postgres-db-v16-aat.postgres.database.azure.com'
AZURE_DB='dbuserprofile'
SUBJECT='LOCATION-REF-DATA-DB Daily Report'
TO_ADDRESS='sabina.sharangdhar@hmcts.net'
CC_ADDRESS='sabina.sharangdhar@hmcts.net'
YESTERDAY=$(date -d "yesterday" '+%Y%m%d')
DEFAULT_DATE=$(date +%Y%m%d)
DAYSAGO=$(date -d "7 days ago" '+%Y%m%d 00:00:00')
OUTPUT_DIR=/tmp
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
# OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
USERPROFILEIDS=${OUTPUT_DIR}/"USERPROFILEIDS"

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo " =====  Call IDAM to check user status ===== "

# Set the hostnames database user and passwordnames for the userprofile db
if [ $ALL_USERS_FLAG -ne  'true') ]
then
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT idam_id FROM dbuserprofile.user_profile where idam_status ='SUSPENDED' and last_updated >= NOW() - INTERVAL '14 DAYS' LIMIT 5;"  >> ${USERPROFILEIDS}
else
psql -t -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} -c "SELECT idam_id FROM dbuserprofile.user_profile where idam_status ='SUSPENDED' LIMIT 5;"  >> ${USERPROFILEIDS}
fi
#CMD1="$SSH_CMD1 $PSQL_CMD1"
echo "idams from user profile"
${USERPROFILEIDS} | tail -n +3 | tee tmp/user_profile_idams.txt

while read -r line; do
  tables+=("$line")
done < user_profile_idams.txt

HEADERS='Content-Length:0,Host:idam-api.aat.platform.hmcts.net,Accept: */*,Accept-Encoding: gzip, deflate, br,Connection: keep-alive,Content-Type: application/x-www-form-urlencoded'

TOKEN_CMD=$ CURL -X GET 'https://idam-api.aat.platform.hmcts.net/o/token?grant_type=password&username='+$USER+'&password='+$PASS+'&client_id='+$CLIENT+'&client_secret='+$SECRET+'&scope=openid profile roles manage-user create-user search-user', 'headers=' +$HEADERS
result=`$TOKEN_CMD | grep "Test:"`
echo "TOKEN :"$TOKEN_CMD


tables=()
for table in ${tables[@]}; do
 echo "helolo"
  cmd1=$(curl -X GET 'https://idam-testing-support-api.aat.platform.hmcts.net/test/idam/users/' + $table  -H 'accept: */*' -H 'Authorization:Bearer '+$TOKEN)
  idam_entry_count=$( ${cmd1} | tail -n +3 | tee idam_entries.txt)

  if [ idam_entry_count -ne 0 ]
    then
      echo -e "${Col_Grn} Suspended user in User profile found on IDAM $table ${Col_Off}"
      echo "idam_entry_count:  $db1_entry_count  and userprofile idam : $table"
    else
      echo -e "${Col_Red}Suspended user in User profile not found on IDAM $table ${Col_Off}"
    fi
done
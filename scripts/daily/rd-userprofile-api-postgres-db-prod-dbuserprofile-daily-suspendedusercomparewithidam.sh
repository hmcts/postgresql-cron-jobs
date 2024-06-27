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

USER="up.demo.cgi@hmcts.net"
PASS="Password123"
CLIENT="rd-professional-api"
SECRET="a20c3cf7-1fb4-4bcf-89ec-963c05a13f71"

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo " =====  Call IDAM to check user status ===== "
# SSH commands to connect to the servers
SSH_CMD1="ssh -F /Users/sabinasharangdhar/.ssh/az_config bastion-nonprod.platform.hmcts.net"

if [ $ALL_USERS_FLAG -ne 0 ]
then
PSQL_CMD1='psql "sslmode=require user='$USER1' password='$PASS1' host='$DB1_HOST' dbname='$DB1_NAME' port=5432" -c "select idam_id from user_profile where idam_status ='SUSPENDED' and last_updated >= NOW() - INTERVAL '14 DAYS' LIMIT 5 ;"'
 else
PSQL_CMD1='psql "sslmode=require user='$USER1' password='$PASS1' host='$DB1_HOST' dbname='$DB1_NAME' port=5432" -c "SELECT idam_id FROM dbuserprofile.user_profile u LIMIT 5;"'
fi
CMD1="$SSH_CMD1 $PSQL_CMD1"
echo "idams from user profile"
${CMD1} | tail -n +3 | tee user_profile_idams.txt

while read -r line; do
  tables+=("$line")
done < user_profile_idams.txt

HEADERS='-H Content-Length:0 -H Host:idam-api.aat.platform.hmcts.net -H Accept:*/* -H Accept-Encoding:gzip,deflate,br -H Connection:keep-alive -H Content-Type:application/x-www-form-urlencoded'
TOKEN_CMD=$ CURL -X  GET 'https://idam-api.aat.platform.hmcts.net/o/token?grant_type=password&username='$USER'&password='$PASS'&client_id='$CLIENT'&scope=openid/profile/roles/manage-user/create-user/search-user&client_secret='$SECRET $HEADERS
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
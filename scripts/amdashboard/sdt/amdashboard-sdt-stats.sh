#!/bin/bash

CURRENT_DATE=$(date +%d"/"%m"/"%Y)
CURRENT_TIME=$(date +%T)

AZURE_DB="civil_sdt"

OUTPUT_DIR="/tmp"
OUTPUT_FILENAME="SDTCLOUD_stats.txt"
OUTPUT_FILEPATH=${OUTPUT_DIR}/${OUTPUT_FILENAME}
ID_FILENAME=bais_id
ID_FILEPATH=${OUTPUT_DIR}/${ID_FILENAME}

QUERY_RECENT_SUBMISSIONS="./queries/amdashboard-sdt-recent.sh"
QUERY_DEAD_LETTER_QUEUE="./queries/amdashboard-sdt-dlq.sh"
QUERY_FORWARDED_REQUESTS="./queries/amdashboard-sdt-forwarded.sh"
QUERY_RECEIVED_REQUESTS="./queries/amdashboard-sdt-received.sh"

function log() {
  echo $(date "+%Y-%m-%d %T%z")" ${1}"
}

function deleteIdFile() {
  rm -f ${ID_FILEPATH}
}

function errHandler() {
  log "Error occurred during creation/sending of stats file"
  deleteIdFile
  exit 1
}

trap errHandler ERR

log "Count number of forwarded requests"
STUCK_FORWARDED_COUNT=$(psql -h ${AZURE_DB_HOSTNAME} -d ${AZURE_DB} -U ${AZURE_DB_USERNAME} -c "$(eval ${QUERY_FORWARDED_REQUESTS})")
if [ ${STUCK_FORWARDED_COUNT} == 0 ]
then
  STUCK_FORWARDED_STATUS="ok"
else
  STUCK_FORWARDED_STATUS="warn"
fi

log "Count number of received requests"
STUCK_RECEIVED_COUNT=$(psql -h ${AZURE_DB_HOSTNAME} -d ${AZURE_DB} -U ${AZURE_DB_USERNAME} -c "$(eval ${QUERY_RECEIVED_REQUESTS})")
if [ ${STUCK_RECEIVED_COUNT} == 0 ]
then
  STUCK_RECEIVED_STATUS="ok"
else
  STUCK_RECEIVED_STATUS="warn"
fi

log "Generating stats file"
{
echo ${CURRENT_DATE} ${CURRENT_TIME}
echo "[SDTRecent]"
echo "CREATED,UPDATED,SDT_REQUEST_REFERENCE,REQUEST_STATUS,REQUEST_TYPE"
psql -h ${AZURE_DB_HOSTNAME} -d ${AZURE_DB} -U ${AZURE_DB_USERNAME} -c "$(eval ${QUERY_RECENT_SUBMISSIONS})"
echo ""
echo "[SDTStuck]"
echo "NAME,TIME,DESCRIPTION,COUNT,RESULT"
echo "Forwarded,${CURRENT_DATE} ${CURRENT_TIME},Request stuck in Forwarded state,${STUCK_FORWARDED_COUNT},${STUCK_FORWARDED_STATUS}"
echo "Received,${CURRENT_DATE} ${CURRENT_TIME},Request stuck in Received state,${STUCK_RECEIVED_COUNT},${STUCK_RECEIVED_STATUS}"
echo ""
echo "[SDTDLQ]"
echo "CREATED,SDT_REQUEST_REFERENCE,REQUEST_STATUS,REQUEST_TYPE"
psql -h ${AZURE_DB_HOSTNAME} -d ${AZURE_DB} -U ${AZURE_DB_USERNAME} -c "$(eval ${QUERY_DEAD_LETTER_QUEUE})"
echo ""
echo "[Additional Checks]"
echo "NAME,TIME,DESCRIPTION,RESULT,STATUS"
} > ${OUTPUT_FILEPATH}

log "Creating identity file"
deleteIdFile
touch ${ID_FILEPATH}
chmod 600 ${ID_FILEPATH}
echo "${BAIS_SFTP_SERVER_SSH_KEY}" >> ${ID_FILEPATH}
log "Sending stats file via sftp"
sftp -v -v -v -P ${BAIS_SFTP_SERVER_PORT} -i ${ID_FILEPATH} -oStrictHostKeyChecking=accept-new -oHostKeyAlgorithms=+ssh-rsa ${BAIS_SFTP_SERVER_USERNAME}@${BAIS_SFTP_SERVER} <<EOF
put ${OUTPUT_FILEPATH}
bye
EOF
log "Removing identity file"
deleteIdFile
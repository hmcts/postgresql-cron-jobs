#!/bin/bash
# vi:syntax=sh

## IRON MOUNTAIN DUMP SCRIPT
# JIRA - https://tools.hmcts.net/jira/browse/RDO-3276

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

  # Set date and output VARS

DEFAULT_DATE=$(date +%Y%m%d)
#DEFAULT_DATE=20190101
OUTPUT_DIR=/var/lib/probate2im
OUTPUT_FILE_NAME=moj.txt
FILELOCAL=moj.txt
FTPTRANSMISSIONFILE=error
SFTPHOSTNAME="sftp.ironmountain.eu"
SFTPUSERNAME="CCD-HMCTS"
SFTPPASSWORD="6WOpLC1k"
YESTERDAY=$(date -d "yesterday 13:00" '+%Y-%m-%d')  
#YESTERDAY=2019-04-03  


log "Iron Mountain Dump Complete"

#SFTP CONNECTION
sshpass -p $SFTPPASSWORD sftp $SFTPUSERNAME@$SFTPHOSTNAME << !
	put $FILELOCAL
	ls -ltr
	bye
!

sleep 5
FTPSTATUS=$( grep -ic "Connected to sftp.ironmountain.eu" ${FTPTRANSMISSIONFILE})
if [ $FTPSTATUS -eq 1 ]
then
  echo "Success"
else
  echo "I didnt find postfix"
fi

#!/bin/bash
set -fex

function log() {
  echo $(date --rfc-3339=seconds)" ${1}"
}

# Set VArs
AZURE_DB_USERNAME='DTS Platform Operations SC'
AZURE_HOSTNAME='rd-judicial-ref-api-postgres-db-v16-prod.postgres.database.azure.com'
AZURE_DB='dbjuddata'
SUBJECT='REF-DATA-JUDICIAL-DATA Monthly Cron Job Report'
TO_ADDRESS='aneesa.asghar@hmcts.net'
CC_ADDRESS='sabina.sharangdhar@hmcts.net'
DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_DIR=/tmp
FILESUB=$(echo ${SUBJECT} | cut -d' ' -f 1,2,3 | tr ' ' -)
OUTPUT_FILE_NAME=${DEFAULT_DATE}_${AZURE_DB}_${FILESUB}.csv
ATTACHMENT=${OUTPUT_DIR}/${OUTPUT_FILE_NAME}

function errorHandler() {
  local dump_failed_error="${AZURE_HOSTNAME} ${AZURE_DB} Dump extract for ${DEFAULT_DATE}"
  log "${dump_failed_error}"
  echo ""
}

trap errorHandler ERR

echo "encrypted_org_name,org_type,key,value" >> ${ATTACHMENT}
psql -t sslmode=require -U "${AZURE_DB_USERNAME}" -h ${AZURE_HOSTNAME}  -d ${AZURE_DB} --csv -c "select jup.personal_code as PersonalCode , jup.ejudiciary_email as Email, jup.known_as as KnownAs, jup.full_name as FullName, jup.surname as  Surname,
                                                                                                 jup.created_date as JOHCreatedDate, jup.last_working_date as LasworkingDate, jup.retirement_date as Retirementdate, jup.date_of_deletion as DateOfDeletion, jup.deleted_flag as DeletedFlag,
                                                                                                 joa.appointment as Appointment, joa.appointment_type as AppointmentType, joa.start_date as AppointmentStartDate, joa.end_date as AppointmentEndDate, joa."location" as JoHLocation,
                                                                                                 joa2.lower_level  as LowerLevel_Authorisation_name, joa2.jurisdiction  as Jurisdiction, joa2.start_date as AuthorisationStartDate, joa2.end_date as AuthorisationEndDate
                                                                                                 , jar.title  as AdditionalRole
                                                                                                 from dbjudicialdata.judicial_user_profile jup
                                                                                                 left join dbjudicialdata.judicial_office_appointment joa on joa.personal_code = jup.personal_code
                                                                                                 left join dbjudicialdata.judicial_office_authorisation joa2 on joa.personal_code = joa2.personal_code
                                                                                                 left join dbjudicialdata.judicial_additional_roles jar on jup.personal_code  = jar.personal_code

                                                                                                 group by jup.personal_code , jup.ejudiciary_email, jup.known_as, jup.full_name, jup.surname,
                                                                                                 jup.created_date , jup.last_working_date, jup.retirement_date, jup.date_of_deletion, jup.deleted_flag,
                                                                                                 joa.appointment , joa.appointment_type, joa.start_date, joa.end_date, joa."location",
                                                                                                 joa2.jurisdiction , joa2.start_date, joa2.end_date , joa2.lower_level, jar.title;"  >> ${ATTACHMENT}



log "Finished dumping Report on ${DEFAULT_DATE}"
log "Sending email with  Report results to: ${TO_ADDRESS} ${CC_ADDRESS}"

filesize=$(wc -c ${ATTACHMENT} | awk '{print $1}')
if [[ $filesize -gt 1000000 ]]
then
  gzip ${ATTACHMENT}
  ATTACHMENT=${ATTACHMENT}.gz
fi
echo ${ATTACHMENT}

swaks -f $FROM_ADDRESS -t $TO_ADDRESS,$CC_ADDRESS --server smtp.sendgrid.net:587   --auth PLAIN -au apikey -ap $SENDGRID_APIKEY -attach ${ATTACHMENT} --header "Subject: ${SUBJECT}" --body "Please find attached the report for the monthly judicial data retrieval from ${AZURE_HOSTNAME}/${AZURE_DB}"
log "email sent"
rm ${ATTACHMENT}

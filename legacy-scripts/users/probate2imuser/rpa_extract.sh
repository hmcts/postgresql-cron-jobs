#!/bin/bash
# vi:syntax=sh

set -ue
function log() {
          echo $(date --rfc-3339=seconds)" ${1}"
  }

# Set VArs

YESTERDAY=$(date -d "yesterday" '+%Y%m%d') 
DEFAULT_DATE=$(date +%Y%m%d) 
#DEFAULT_DATE=20190322 
OUTPUT_DIR=/tmp
OUTPUT_FILE_NAME=${DEFAULT_DATE}RDO-4389.csv
TO_ADDRESS=alliu.balogun@hmcts.net
CC_ADDRESS=no-reply@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
FAILURE_ADDRESS=no-reply@hmcts.net
environment=`uname -n`

function errorHandler() {
  local dump_failed_error="One-off dumps ${DEFAULT_DATE}"

  log "${dump_failed_error}"

  echo -e "Hi\n${dump_failed_error} today" | mail -s "One-off ${DEFAULT_DATE} failed in ${environment}" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS}
}

trap errorHandler ERR

if [[ -z "${CC_ADDRESS}" ]]; then
    CC_COMMAND=""
    CC_LOG_MESSAGE=""
else
    CC_COMMAND="-c ${CC_ADDRESS}"
    CC_LOG_MESSAGE="copied to: ${CC_ADDRESS}"
fi

  QUERY=$(cat <<EOF
COPY (SELECT O.ID AS ORGANISATION_ID
,O.SRA_ID AS SRA_ID
,O.ORGANISATION_ID AS ORGANISATION_IDENTIFIER
,O.LAST_UPDATED AS LAST_UPDATED
,O.COMPANY_NUMBER AS COMPANY_NUMBER
,O.SRA_REGULATED AS SRA_REGULATED
,O.URL AS COMPANY_URL
,O.NAME AS NAME
,O.STATUS AS STATUS
,U.ID AS PROFESSIONAL_USER_ID
,U.FIRST_NAME AS FIRST_NAME
,U.LAST_NAME AS LAST_NAME
,U.STATUS AS USER_STATUS_PLACEHOLDER
,U.EMAIL_ID AS EMAIL_ADDRESS
,O.LAST_UPDATED AS USER_LAST_UPDATED_PLACEHOLDER
,U.ORGANISATION_ID AS "PROFESSIONAL_USER$ORGANISATION_ID"
,A.ID AS PAYMENT_ACCOUNT_ID
,A.PBA_NUMBER AS PBA_NUMBER
,A.ORGANISATION_ID AS PAYMENT_ACCOUNT$ORGANISATION_ID
,C.ID AS CONTACT_INFORMATION_ID
,C.ADDRESS_LINE1 AS ADDRESS_LINE1
,C.ADDRESS_LINE2 AS ADDRESS_LINE2
,C.TOWN_CITY AS TOWN_CITY
,C.COUNTRY AS COUNTRY
,C.COUNTY AS COUNTY
,C.POSTCODE AS POSTCODE
,C.ORGANISATION_ID AS CONTACT_INFORMATION$ORGANISATION_ID
,C.LAST_UPDATED AS CONTACT_INFORMATION_LAST_UPDATED_PLACEHOLDER
,D.ID AS DOMAIN_ID
,D.HOST AS DOMAIN_NAME
,D.ID AS DOMAIN_IDENTIFIER
,O.LAST_UPDATED AS DOMAIN_LAST_UPDATED_PLACEHOLDER
,D.ORGANISATION_ID AS DOMAIN$ORGANISATION_ID
,X.ID AS DX_ADDRESS_ID
,X.DX_EXCHANGE AS DX_EXCHANGE
,X.DX_NUMBER AS DX_NUMBER
,O.LAST_UPDATED AS DX_ADDRESS_LAST_UPDATED_PLACEHOLDER
,C.ID AS DX_ADDRESS$CONTACT_INFORMATION_ID
FROM ORGANISATION O
JOIN PROFESSIONAL_USER U ON U.ORGANISATION_ID = O.ID
LEFT JOIN DX_ADDRESS X ON O.DX_ADDRESS_ID = X.ID
LEFT JOIN PAYMENT_ACCOUNT A ON A.ORGANISATION_ID = O.ID
LEFT JOIN CONTACT_INFORMATION C ON C.ORGANISATION_ID = O.ID
LEFT JOIN DOMAIN D ON D.ORGANISATION_ID = O.ID) 
TO STDOUT with csv header
EOF
)

## Which DB to query? here

##psql -U probateman_user@probatemandb-postgres-db-prod -h probatemandb-postgres-db-prod.postgres.database.azure.com -p 5432 -d probatemandb -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
#psql -U ccdro@ccd-data-store-api-postgres-db-prod -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
psql -U prdorg_user@rpa-rd-professional-postgres-db-prod -h rpa-rd-professional-postgres-db-prod.postgres.database.azure.com -p 5432 -d prdorg_db -c "${QUERY}"  > ${OUTPUT_DIR}/${OUTPUT_FILE_NAME}
##

log "One-off dumps ${DEFAULT_DATE}"

log "One-off dumps results to: ${TO_ADDRESS} ${CC_LOG_MESSAGE}"

echo -e "" | mail -s "One-off dumps " -a ${OUTPUT_DIR}/${OUTPUT_FILE_NAME} -r $FROM_ADDRESS ${TO_ADDRESS} ${CC_ADDRESS} 


log "One-off dump Complete"

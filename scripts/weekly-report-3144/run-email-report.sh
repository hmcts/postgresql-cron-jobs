#!/bin/bash
set -eu

source 'function-declarations.sh'

log $(date --rfc-3339=seconds)" ${1}"

# Set access token
log "Creating Certificate"

trap "y" INT
az ssh config --ip \*.platform.hmcts.net --file ~/.ssh/prod

log "Certificate created"
log "Setting PGPASSWORD with current access token"

PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

if [ -z "$PGPASSWORD" ];
then
    log "Problem setting PGPASSWORD! Check that you have azure authentication."
    exit 1
fi

export PGPASSWORD

log "Token generated"
log "Connecting to bastion"

BASTION="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com:5432 bastion-${PLATFORM}.platform.hmcts.net"

log "DB_HOST: ${DB_HOST}"
log "DB_NAME: ${DB_NAME}"
log "DB_USER: ${DB_USER}"

log "Logging into psql and running query"

# shellcheck disable=SC2087
ssh -L 5440:${BASTION} -F ~/.ssh/prod <<EOF

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}"

\! pwd
\copy (SELECT reference, state, data ->>'hearingCentre' AS hearing_centre, data ->>'ariaListingReference' AS listing_Reference, data ->>'appealReferenceNumber' AS SC_number, data ->>'isDecisionAllowed' AS decision_outcome, data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded FROM case_data WHERE case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7) ) TO '${OUTPUT_FILE_NAME}' WITH DELIMITER ',' CSV HEADER;

EOF

log "Finished running query. Connection to bastion closed."

log "Copying ${OUTPUT_FILE_NAME} from vm to local using scp"
AZ_HOST=""
scp -F ~/.ssh/config ${AZ_HOST}:${OUTPUT_FILE_NAME} ${OUTPUT_FILE_NAME}

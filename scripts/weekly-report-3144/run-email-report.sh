#!/bin/bash

set -x

echo $(date --rfc-3339=seconds)" ${1}"

# Set access token
echo "Creating Certificate"

trap "y" INT

az ssh config --ip \*.platform.hmcts.net --file ~/.ssh/prod

echo "Certificate created"
echo "Setting PGPASSWORD with current access token"

PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

if [ -z "$PGPASSWORD" ];
then
    echo "Problem setting PGPASSWORD! Check that you have azure authentication."
    exit 1
fi

export PGPASSWORD

echo "Token generated"
echo "Setting required variables"

export ENV="demo"
export PLATFORM="nonprod"

export DB_HOST="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com"
export DB_NAME=ccd_data_store
export DB_USER="DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-${ENV}"
DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_FILE_NAME=${DEFAULT_DATE}-weekly-cases.csv

echo "Connecting to the bastion on port 5432"

BASTION="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com:5432 bastion-${PLATFORM}.platform.hmcts.net"

# shellcheck disable=SC2087
ssh -L 5440:${BASTION} -F ~/.ssh/prod <<EOF

echo "DB_HOST: ${DB_HOST}"
echo "DB_NAME: ${DB_NAME}"
echo "DB_USER: ${DB_USER}"
echo "PGPASSWORD: **************"
echo "Logging into psql"
echo "Running query"

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}"

\! pwd
\copy (SELECT reference, state, data ->>'hearingCentre' AS hearing_centre, data ->>'ariaListingReference' AS listing_Reference, data ->>'appealReferenceNumber' AS SC_number, data ->>'isDecisionAllowed' AS decision_outcome, data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded FROM case_data WHERE case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7) ) TO '${OUTPUT_FILE_NAME}' WITH DELIMITER ',' CSV HEADER;

EOF

echo "Finished running query. Connection to bastion closed."

export DEFAULT_DATE
export OUTPUT_FILE_NAME
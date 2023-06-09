#!/bin/bash 

echo $(date --rfc-3339=seconds)" ${1}"

sleep 0.5

# Set access token
echo "Creating Certificate"

echo . 
sleep 0.5 
echo .
sleep 0.5 
echo .
sleep 0.5

az ssh config --ip \*.platform.hmcts.net --file ~/.ssh/prod &

trap "y" INT

sleep 1

printf "\nCertifcate created\n"

sleep 0.5

printf "\nSetting PGPASSWORD with current access token\n"

export PGPASSWORD=$(az account get-access-token --resource-type oss-rdbms --query accessToken -o tsv)

sleep 0.5

if [ -z "$PGPASSWORD" ];
then
    echo "Problem setting PGPASSWORD! Check that you have azure authentication."
    exit
fi

printf "\nToken generated\n"

printf "\nSetting required variables\n"

echo . 
sleep 0.5 
echo .
sleep 0.5 
echo .
sleep 0.5

export ENV="demo"
export PLATFORM="nonprod"

export DB_HOST="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com"
export DB_NAME=ccd_data_store
export DB_USER="DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-${ENV}"
export DEFAULT_DATE=$(date +%Y%m%d)
export OUTPUT_FILE_NAME=${DEFAULT_DATE}-weekly-cases.csv

sleep 1

printf "\nConnecting to the bastion on port 5432\n"
sleep 1

BASTION="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com:5432 bastion-${PLATFORM}.platform.hmcts.net"

ssh -L 5440:${BASTION} -F ~/.ssh/prod <<EOF

sleep 1
echo "DB_HOST: ${DB_HOST}"
echo "DB_NAME: ${DB_NAME}"
echo "DB_USER: ${DB_USER}"
echo "PGPASSWORD: ${PGPASSWORD:0:9}**************"
printf "\nLogging into psql\n"
sleep 1
printf "\nRunning query\n \n\n"

psql "sslmode=require host=${DB_HOST} dbname=${DB_NAME} user=${DB_USER} port=5432 password=${PGPASSWORD}"

\! pwd
\copy (SELECT reference, state, data ->>'hearingCentre' AS hearing_centre, data ->>'ariaListingReference' AS listing_Reference, data ->>'appealReferenceNumber' AS SC_number, data ->>'isDecisionAllowed' AS decision_outcome, data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded FROM case_data WHERE case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7) ) TO '${OUTPUT_FILE_NAME}' WITH DELIMITER ',' CSV HEADER;

EOF
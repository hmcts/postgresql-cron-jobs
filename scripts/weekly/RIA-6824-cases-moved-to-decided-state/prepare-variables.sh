#!/bin/bash
set -eu

if [ -z ${AZURE_HOSTNAME+x} ];
then
  log "AZURE_HOSTNAME environment variable not set. Please set it to the database instance you want to use, for example ccd-data-store-api-postgres-db-v11-demo.postgres.database.azure.com"
  echo "Hint:"
  echo "export AZURE_HOSTNAME=ccd-data-store-api-postgres-db-v11-demo.postgres.database.azure.com"
  exit 1
fi

if [ -z ${AZURE_DB_USERNAME+x} ];
then
  log "AZURE_DB_USERNAME environment variable not set. Please set it to the database instance you want to use, for example DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-demo"
  echo "Hint:"
  echo "export AZURE_DB_USERNAME=DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-demo"
  exit 2
fi


AZURE_DB=ccd_data_store
# shellcheck disable=SC2089

DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_FILE_NAME=${DEFAULT_DATE}-weekly-cases.csv
ATTACHMENT=${DEFAULT_DATE}-weekly-cases-sorted.csv


# Email addresses
# FROM_ADDRESS is populated in weekly-reports.yml
export TO_ADDRESS=""
export CC_ADDRESS=""

# Database
export AZURE_HOSTNAME
export AZURE_DB
# shellcheck disable=SC2090
export AZURE_DB_USERNAME

# Internal variables
export DEFAULT_DATE
export OUTPUT_FILE_NAME
export ATTACHMENT


export VARIABLES_SET=1
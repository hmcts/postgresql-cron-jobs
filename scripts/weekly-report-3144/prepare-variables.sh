#!/bin/bash
set -eu

ENV="demo"

AZURE_HOSTNAME="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com"
AZURE_DB=ccd_data_store
AZURE_DB_USERNAME="DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-${ENV}"

DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_FILE_NAME=${DEFAULT_DATE}-weekly-cases.csv
ATTACHMENT=${DEFAULT_DATE}-weekly-cases-sorted.csv


# Environment
export ENV

# Email addresses
export FROM_ADDRESS=""
export TO_ADDRESS=""
export CC_ADDRESS=""

# Database
export AZURE_HOSTNAME
export AZURE_DB
export AZURE_DB_USERNAME

# Internal variables
export DEFAULT_DATE
export OUTPUT_FILE_NAME
export ATTACHMENT


export ENVIRONMENT_IS_SET=1
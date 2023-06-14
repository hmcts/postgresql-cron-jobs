#!/bin/bash

set -xeu

DB_HOST="ccd-data-store-api-postgres-db-v11-${ENV}.postgres.database.azure.com"
DB_NAME=ccd_data_store
DB_USER="DTS\ CFT\ DB\ Access\ Reader@ccd-data-store-api-postgres-db-v11-${ENV}"


DEFAULT_DATE=$(date +%Y%m%d)
OUTPUT_FILE_NAME=${DEFAULT_DATE}-weekly-cases.csv
ATTACHMENT=${DEFAULT_DATE}-weekly-cases-sorted.csv

# Environment
export ENV="demo"
export PLATFORM="nonprod"

# Email addresses
export FROM_ADDRESS=""
export TO_ADDRESS=""
export CC_ADDRESS=""

export DB_HOST
export DB_NAME
export DB_USER

export DEFAULT_DATE
export OUTPUT_FILE_NAME
export ATTACHMENT






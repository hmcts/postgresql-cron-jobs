#!/bin/bash
set -eu

source 'function-declarations.sh'

if ! [[ -e "${OUTPUT_FILE_NAME}" ]];
then
    log "There was an error reading the file created in the previous step."
    exit 1
fi

# Prints first 3 results
chmod 777 ${OUTPUT_FILE_NAME}

log "Sorting... Displaying first three results"
# Sorts csv file by dateUploaded
ATTACHMENT=${DEFAULT_DATE}-weekly-cases-sorted.csv
csvsort --reverse -c 7 ${OUTPUT_FILE_NAME} > ${ATTACHMENT}

export ATTACHMENT

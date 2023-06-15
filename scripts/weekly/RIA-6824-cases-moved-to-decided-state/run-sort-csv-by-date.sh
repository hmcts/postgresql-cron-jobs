#!/bin/bash
set -eu

source 'function-declarations.sh'

if ! [[ -e "${OUTPUT_FILE_NAME}" ]];
then
    log "There was an error reading the file created in the previous step."
    exit 4
fi

# Prints first 3 results
chmod 777 ${OUTPUT_FILE_NAME}

log "Sorting csv file by dateUploaded"
csvsort --reverse -c 7 ${OUTPUT_FILE_NAME} > ${ATTACHMENT}

export ATTACHMENT

#!/bin/bash

set -x

ATTACHMENT="${OUTPUT_FILE_NAME}"

if ! [[ -e "${ATTACHMENT}" ]];
then
    echo "There was an error reading the file create in the previous step."
    exit 1
fi

# Prints first 3 results
chmod 777 ${ATTACHMENT}

echo "Sorting... Displaying first three results"
# Sorts csv file by dateUploaded
csvsort --reverse -c 7 ${ATTACHMENT} > ${DEFAULT_DATE}-weekly-cases-sorted.csv


export ATTACHMENT

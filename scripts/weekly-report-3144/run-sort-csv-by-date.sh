#!/bin/bash

set -x

AZ_HOST=""
DESTINATION=""
ATTACHMENT="${DESTINATION}/${OUTPUT_FILE_NAME}"

if ! [[ -e "${ATTACHMENT}" ]];
then
    echo "There was an error reading the file create in the previous step."
    exit 1
fi

# Copy from vm to local directory
echo "Copying ${OUTPUT_FILE_NAME} from vm to local"
sudo scp -F ~/.ssh/config ${AZ_HOST}:${OUTPUT_FILE_NAME} ${DESTINATION}

# Prints first 3 results
chmod 777 ${ATTACHMENT}

echo "Sorting... Displaying first three results"
# Sorts csv file by dateUploaded
csvsort --reverse -c 7 ${ATTACHMENT} > ${DESTINATION}/${DEFAULT_DATE}-weekly-cases-sorted.csv


export ATTACHMENT

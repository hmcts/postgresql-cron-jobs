AZ_HOST=""
DESTINATION=""
ATTACHMENT="${DESTINATION}/${OUTPUT_FILE_NAME}"

if ! [[ -e "${ATTACHMENT}" ]];
then
    echo "There was an error creating the file, check connection to bastion"
    exit
fi

# Copy from vm to local directory
printf "\n\nCopying ${OUTPUT_FILE_NAME} from vm to local\n\n"
printf "\n\n"
sudo scp -F ~/.ssh/config ${AZ_HOST}:${OUTPUT_FILE_NAME} ${DESTINATION}

sleep 1

# Prints first 3 results
chmod 777 ${ATTACHMENT}

printf "Sorting... Displaying first three results\n\n" 
# Sorts csv file by dateUploaded
csvsort --reverse -c 7 ${ATTACHMENT} | head -n 4

sleep 1
csvsort --reverse -c 7 ${ATTACHMENT} > ${DESTINATION}/${DEFAULT_DATE}-weekly-cases-sorted.csv
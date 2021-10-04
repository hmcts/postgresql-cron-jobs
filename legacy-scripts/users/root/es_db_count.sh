#!/bin/sh
#Script to check if values from ES Index, GrantOfRepresentation matches count from case_type_id=GrantOfRepresentation in CCD DB

# Alliu Balogun 08/08/2019

#Fire ES Query
ssh  -i $HOME/.ssh/logstash elkadmin@10.96.85.5 /home/elkadmin/gop_count.sh > /dev/null 2>&1;

# Declare vars
TO_ADDRESS=Benjamin.Neill@hmcts.net
CC_ADDRESS=alliu.balogun@hmcts.net
FROM_ADDRESS=alliu.balogun@reform.hmcts.net
#FAILURE_ADDRESS=dcd-devops-support@hmcts.net
FAILURE_ADDRESS=alliu.balogun@hmcts.net
SCRIPTTIME=`date +%d/%m/%Y' '%T`

DBCOUNT=`psql -t -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "SELECT COUNT(*) FROM case_data WHERE jurisdiction='PROBATE'  AND case_type_id='GrantOfRepresentation';"`

ESCOUNT=`ssh  -i $HOME/.ssh/logstash elkadmin@10.96.85.5 cat /tmp/gop_es_count.txt | /usr/bin/awk '{print $7}'`



if [ $DBCOUNT = $ESCOUNT ]

 then COUNTSTATUS="Count matches, do nothing!"
 	echo ""
        echo "DB Count is : $DBCOUNT"
 	echo "Elastic Search Count is : $ESCOUNT"

 else COUNTSTATUS="Count mis-match"

        echo -e "Current Status is:  ${COUNTSTATUS} \n\n DB Count is: ${DBCOUNT} \n ES Count is: ${ESCOUNT} \n\n Please investigate!!! \n\n See Confluence page : https://hmcts.net \n\n "| mail -s "Houston!!! on ${SCRIPTTIME} ES and DB counts are out of SYNC. Please investigate" -r "noreply@reform.hmcts.net (DevOps)" ${FAILURE_ADDRESS} ${TO_ADDRESS}

fi

echo ""
echo "Current Status is:  $COUNTSTATUS"

#!/bin/bash
        for referenceid in `cat sscs_referenceid.txt`;

        do
        CASEID=`psql -t -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "select data #> '{regionalProcessingCenter,name}' FROM case_data WHERE reference=$referenceid"`
        STATE_NAME=`psql -t -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "select state_name from case_event where case_data_id IN (select id from case_data where reference =$referenceid) order by id desc limit 1"`

QUERY=$(cat <<EOF
--UPDATE case_data SET state='BOCaseMatchingIssueGrant', last_modified = now(), version=version+1 WHERE reference=$referenceid;
--UPDATE case_data SET data = jsonb_set(data,'{region}','$CASEID') WHERE reference = $referenceid;
select state_name from case_event where case_data_id IN (select id from case_data where reference =$referenceid) order by id desc limit 1;


EOF
)

psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
#psql -U ccd@ccd-data-store-api-postgres-db-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $CASEID $referenceid
    
	done
	  
	echo $CASEID $referenceid

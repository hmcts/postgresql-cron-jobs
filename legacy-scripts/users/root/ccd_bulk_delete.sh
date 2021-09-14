#!/bin/bash
## BULK Deletes in CCD

#referenceid=1594642772192927;
        for referenceid in `cat cmc_delete_cases.txt`;


      do

QUERY=$(cat <<EOF
 
BEGIN;	
  DELETE FROM case_users_audit WHERE case_data_id = (SELECT id FROM case_data WHERE reference = ($referenceid));
  DELETE FROM case_users WHERE case_data_id = (SELECT id FROM case_data WHERE reference = ($referenceid));
  DELETE FROM case_event_significant_items WHERE case_event_id IN (SELECT id FROM case_event WHERE case_data_id IN (SELECT id FROM case_data WHERE reference = ($referenceid)));
  DELETE FROM case_event WHERE case_data_id = (SELECT id FROM case_data WHERE reference = ($referenceid));
  DELETE FROM case_data WHERE reference = ($referenceid);
COMMIT;	

EOF
)

#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  
    
	done
	  
	echo $referenceid

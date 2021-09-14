#!/bin/bash
date > start.txt
        for referenceid in `cat sscs_list.txt`;

        do
        CASEID=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "SELECT id FROM case_data WHERE reference=$referenceid"`

QUERY=$(cat <<EOF

 -- Insert case_users insert

 INSERT INTO public.case_users(case_data_id, user_id)
 VALUES ($CASEID, '63515');
 
--COMMIT;	
EOF
)

#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $referenceid
    
	done
	  
	#echo $CASEID $referenceid
	echo $referenceid
date >> start.txt

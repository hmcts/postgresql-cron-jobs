#!/bin/bash
date > start.txt
        for referenceid in `cat cmc_cases.txt`;

        do
        CASEDATAID=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "SELECT id FROM case_data WHERE reference=$referenceid"`


QUERY=$(cat <<EOF

--BEGIN;

 -- Insert case_users insert

INSERT INTO public.case_users(case_data_id, user_id)
	VALUES ($CASEDATAID, '63516');
 
--COMMIT;	
EOF
)

psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $referenceid
    
	done
	  
	echo  $referenceid
date >> start.txt

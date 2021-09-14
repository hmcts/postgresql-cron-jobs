#!/bin/bash
date > start.txt
        for referenceid in `cat cmc_list5.txt`;

        do
        CASEDATAID=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "SELECT id FROM case_data WHERE reference=$referenceid"`

        VERSION=`psql -t --set=sslmode=require -h ccd-definition-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -U ccd@ccd-definition-store-api-postgres-db-v11-prod  -d ccd_definition_store -c "select version from  case_type where  reference='MoneyClaimCase' order by 1 DESC limit 1;"`
        STATE_NAME=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "select trim(state_name) from case_event where case_data_id IN (select id from case_data where reference =$referenceid) order by id desc limit 1"`

QUERY=$(cat <<EOF

BEGIN;
 --UPDATE case_data SET last_modified = now(), version=version+1, state = 'readyForDirections' WHERE reference = $referenceid;   
-- UPDATE case_data SET data = jsonb_set(data,'{respondents, 0, value, responseDeadline}', '"2019-12-18"' , true), last_modified = NOW(), version = version + 1 WHERE jurisdiction = 'CMC' AND reference = $referenceid;   
update case_data set last_modified = NOW(), version = version + 1, data = jsonb_set(data, '{features}', to_jsonb( concat( data->>'features', ',LAPilotEligible'))) WHERE jurisdiction = 'CMC' AND reference = $referenceid;

 INSERT INTO case_event
 (
 id  ,
 created_date ,
 event_id ,
 summary ,
 description ,
 user_id      ,
 case_data_id ,
 case_type_id ,
 case_type_version,
 state_id     ,
 data   ,
 user_first_name,
 user_last_name ,
 event_name   ,
 state_name   ,
 data_classification,
 security_classification 
 )

 SELECT 
 nextval('case_event_id_seq'::regclass), -- case_event_id 
 now(),  -- created_date
 'SupportUpdate', --event_id
 'CMC case update', --summary  
 'Submitting CMC case update', --description 
 '63516', --user_id 
 cd.id , -- case_data_id
 cd.case_type_id, -- case_type_id
 $VERSION, --case_type_version 
 cd.state, --state_id   
 cd.data, -- Taken from case_data (jsonb column)
 'CMC', --user_first_name 
 'AnonCaseworker', --user_last_name
 'Support update', --event_name
 trim('$STATE_NAME'), --state_name
 cd.data_classification, --Taken from case_data (jsonb column)
 cd.security_classification
 FROM case_data cd
 WHERE cd.reference IN ($referenceid);
 
 -- case_users_audit script insert ----
 
 INSERT INTO public.case_users_audit(
	case_data_id, user_id, changed_by_id, action)
	VALUES ($CASEDATAID, '63516', '63516', 'GRANT');

 -- Insert case_users insert

 --INSERT INTO public.case_users(case_data_id, user_id)
    --	VALUES ($CASEDATAID, '63516');
 
COMMIT;	
EOF
)

#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -p 5432 -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $referenceid
    
	done
	  
	echo  $referenceid
date >> start.txt

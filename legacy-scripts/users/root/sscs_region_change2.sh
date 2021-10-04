#!/bin/bash
#date > start.txt
        for referenceid in `cat sscs2.txt`;

        do
        USERID=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "SELECT id FROM case_data WHERE reference=$referenceid"`

#CASEID=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "select data #> '{regionalProcessingCenter,name}' FROM case_data WHERE reference=$referenceid"`

VERSION=`psql -t --set=sslmode=require -h ccd-definition-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -U ccd@ccd-definition-store-api-postgres-db-v11-prod  -d ccd_definition_store -c "select version from  case_type where  reference='Benefit' AND jurisdiction_id=4 order by 1 DESC limit 1;"`
        STATE_NAME=`psql -t -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -U ccd@ccd-data-store-api-postgres-db-v11-prod -d ccd_data_store -c "select trim(state_name) from case_event where case_data_id IN (select id from case_data where reference =$referenceid) order by id desc limit 1"`

 #--UPDATE case_data SET last_modified = now(), version=version+1, data = jsonb_set(data,'{region}','$CASEID') WHERE reference = $referenceid;
 #--UPDATE case_data SET  data = jsonb_set(data,'{dwpFurtherEvidenceStates}','"noAction"') WHERE
 #--UPDATE case_data SET  data = jsonb_set(data,'{dwpFurtherEvidenceStates}','"noAction"') WHERE
 #--jurisdiction='SSCS' AND data->>'dwpFurtherEvidenceStates'='lapsed' AND reference = $referenceid;
 #--UPDATE case_data SET last_modified = now(), version=version+1, data = jsonb_set(data,'{dwpState}','"Withdrawn"') WHERE

QUERY=$(cat <<EOF
 
 UPDATE case_data SET last_modified = now(), version=version+1, data = jsonb_set(data,'{createdInGapsFrom}','"validAppeal"') WHERE
 jurisdiction='SSCS' AND reference = $referenceid;

BEGIN;
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
 'caseUpdated', --event_id
 'SSCS - appeal updated event', --summary
 'Migrating data createdInGapsFrom', --description
 '63515', --user_id 
 cd.id , -- case_data_id
 cd.case_type_id, -- case_type_id
 $VERSION, --case_type_version 
 cd.state, --state_id   
 cd.data, -- Taken from case_data (jsonb column)
 'SSCS', --user_first_name 
 'System Update', --user_last_name
 'Update to case data', --event_name
 trim('$STATE_NAME'), --state_name
 cd.data_classification, --Taken from case_data (jsonb column)
 cd.security_classification
 FROM case_data cd
 WHERE cd.reference IN ($referenceid);
 
 -- case_users_audit script insert ----
 
 INSERT INTO public.case_users_audit(
	case_data_id, user_id, changed_by_id, action)
	VALUES ($USERID, '63515', '63515', 'GRANT');

 -- Insert case_users insert

-- INSERT INTO public.case_users(case_data_id, user_id)
--	VALUES ($USERID, '63515');
 
COMMIT;	
EOF
)

#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $referenceid
    
	done
	  
	#echo $CASEID $referenceid
	echo $referenceid
date >> start.txt

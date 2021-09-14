#!/bin/bash
        for referenceid in `cat referenceid2.txt`;

        do
                CASEID=`psql -t -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "SELECT id FROM case_data WHERE reference=$referenceid"`

QUERY=$(cat <<EOF
UPDATE case_data SET state='BOCaseMatchingIssueGrant', last_modified = now(), version=version+1 WHERE reference=$referenceid;

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
'boHistoryCorrection', --event_id
'Revert to Issue Grant state for incorrect chars in generated Grant', --summary
'Revert to Issue Grant state for incorrect chars in generated Grant', --description
'cfad5bcc-a943-4106-bd0c-0e31fdd1c68c', --user_id
cd.id , -- case_data_id
cd.case_type_id, -- case_type_id
114, --case_type_version
 'BOCaseMatchingIssueGrant', --state_id   
cd.data, -- Taken from case_data (jsonb column)
'probate.system@hmcts.net', --user_first_name
'BOT', --user_last_name
'History Correction', --event_name
'Case Matching (Issue grant)', --state_name
 cd.data_classification, --Taken from case_data (jsonb column)
 cd.security_classification
 FROM case_data cd
 WHERE cd.reference IN ($referenceid);
 
 -- Insert case_users insert

 --INSERT INTO public.case_users(case_data_id, user_id)
--	VALUES ($CASEID, 'cfad5bcc-a943-4106-bd0c-0e31fdd1c68c');
 
 -- case_users_audit script insert ----
 
 INSERT INTO public.case_users_audit(
	case_data_id, user_id, changed_by_id, action)
	VALUES ($CASEID, 'cfad5bcc-a943-4106-bd0c-0e31fdd1c68c', 'cfad5bcc-a943-4106-bd0c-0e31fdd1c68c', 'GRANT');
  
COMMIT;	
EOF
)

#psql -h ccd-data-store-performance.postgres.database.azure.com -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-v11-prod --set=sslmode=require -h ccd-data-store-api-postgres-db-v11-prod.postgres.database.azure.com -p 5432 -d ccd_data_store -c "${QUERY}"  
	echo $CASEID $referenceid
    
	done
	  
	echo $CASEID $referenceid

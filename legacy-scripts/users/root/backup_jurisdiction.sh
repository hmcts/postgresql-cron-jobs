#!/bin/bash
date > start.txt

#case_type_id = 'FinancialRemedyContested'
JURISDICTION_TABLE=FinancialRemedyMVP2
jurisdictionId=FinancialRemedyMVP2

QUERY=$(cat <<EOF

-- create case_users_audit temp table
--SELECT *  INTO case_users_audit_$JURISDICTION_TABLE FROM case_users_audit WHERE case_data_id IN (SELECT id FROM case_data WHERE case_type_id = '$jurisdictionId');

-- create case_users temp table
--.SELECT * INTO case_users_$JURISDICTION_TABLE FROM case_users WHERE case_data_id IN (SELECT id FROM case_data WHERE case_type_id = '$jurisdictionId');

-- create case_event_significant_items temp table
--SELECT * INTO  case_event_significant_items_$JURISDICTION_TABLE FROM case_event_significant_items WHERE case_event_id IN (SELECT id FROM case_event WHERE case_data_id IN (select id FROM case_data WHERE case_type_id = '$jurisdictionId'));

-- create case_event temp table
SELECT * INTO case_event_$JURISDICTION_TABLE FROM case_event WHERE case_data_id IN (SELECT id FROM case_data WHERE case_type_id = '$jurisdictionId');

-- create case_data temp table
SELECT * INTO case_data_$JURISDICTION_TABLE FROM case_data WHERE case_type_id = '$jurisdictionId';

EOF
)

#psql -h 51.140.184.11 -U ccd@ccd-data-store-performance -d ccd_data_store -c "${QUERY}"  
psql -U ccd@ccd-data-store-api-postgres-db-prod --set=sslmode=require -h 51.140.184.11 -p 5432 -d ccd_data_store -c "${QUERY}"  

date >> start.txt

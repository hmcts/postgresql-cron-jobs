#!/bin/bash
cat <<EOF
select '' AS "judicial_user_profile Count" ;
select count (*) from dbjuddata.judicial_user_profile;
select '' AS "dbjuddata.judicial_office_appointment Count" ;
select count (*) from dbjuddata.judicial_office_appointment;
select '' AS "judicial_office_authorisation Count" ;
select count(*) from judicial_office_authorisation;
select '' AS "dbjuddata.base_location_type Count" ;
select count(*) from dbjuddata.base_location_type;
select '' AS "dbjuddata.region_type Count" ;
select count(*) from dbjuddata.region_type;
select '' AS "dbjuddata.dataload_schedular_audit Count" ;
select count(*) as total_audits from dbjuddata.dataload_schedular_audit;
select '' AS "dataload_exception_records Count" ;
select count(*) as total_exception  from dataload_exception_records;
select '' AS "dataload_schedular_audit" ;
select * from dataload_schedular_audit where scheduler_end_time::DATE = current_date;
select '' AS "dataload_exception_records" ;
select * from dataload_exception_records  where updated_timestamp::DATE = current_date;
select '' AS "total_exceptions_personal_today Count" ;
select count(*) as total_exceptions_personal_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_user_profile';
select '' AS "total_exceptions_appointments_today Count" ;
select count(*) as total_exceptions_appointments_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_appointment';
select '' AS "total_exceptions_authorizations_today" ;
select count(*) as total_exceptions_authorizations_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_authorisation';
EOF
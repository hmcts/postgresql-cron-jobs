#!/bin/bash
cat <<EOF
select count (*) from dbjuddata.judicial_user_profile;
select count (*) from dbjuddata.judicial_office_appointment;
select count(*) from judicial_office_authorisation;
select count(*) from dbjuddata.base_location_type;
select count(*) from dbjuddata.region_type;
select count(*) as total_audits from dbjuddata.dataload_schedular_audit;
select count(*) as total_exception  from dataload_exception_records;
select * from dataload_schedular_audit where scheduler_end_time::DATE = current_date;
select * from dataload_exception_records  where updated_timestamp::DATE = current_date;
select count(*) as total_exceptions_personal_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_user_profile';
select count(*) as total_exceptions_appointments_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_appointment';
select count(*) as total_exceptions_authorizations_today from dataload_exception_records where updated_timestamp::DATE = current_date and table_name = 'judicial_office_authorisation';
EOF
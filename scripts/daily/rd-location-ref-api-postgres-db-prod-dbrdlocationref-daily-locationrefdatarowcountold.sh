#!/bin/bash
cat <<EOF
select '' AS "locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC Count" ;
select count (*) from locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC;
--select '' AS "locrefdata.dataload_exception_record Count" ;
--select count(*) as total_exception  from locrefdata.dataload_exception_records;
--select '' AS "locrefdata.dataload_schedular_audit" ;
--select * from locrefdata.dataload_schedular_audit where scheduler_end_time::DATE = current_date;
--select '' AS "locrefdata.dataload_exception_records" ;
--select * from locrefdata.dataload_exception_records  where updated_timestamp::DATE = current_date;
EOF

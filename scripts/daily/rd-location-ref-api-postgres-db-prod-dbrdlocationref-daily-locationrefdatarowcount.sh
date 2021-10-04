#!/bin/bash
cat <<EOF
select count (*) from locrefdata.SERVICE_TO_CCD_CASE_TYPE_ASSOC;
select count(*) as total_exception  from locrefdata.dataload_exception_records;
select * from locrefdata.dataload_schedular_audit where scheduler_end_time::DATE = current_date;
select * from locrefdata.dataload_exception_records  where updated_timestamp::DATE = current_date;
EOF

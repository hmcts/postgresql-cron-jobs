#!/bin/bash
###

  QUERY=$(cat <<EOF
COPY (SELECT
 id,
 created_date,
 event_id,
 summary,
 description,
 user_id,
 case_data_id,
 case_type_id,
 case_type_version,
 state_id,
 data,
 user_first_name,
 user_last_name,
 event_name,
 state_name,
 data_classification,
 security_classification
 FROM case_event
) TO STDOUT WITH CSV HEADER
EOF
)
psql -h ccd-data-store-backup.postgres.database.azure.com -p 5432 -U ccd@ccd-data-store-backup -d ccd_data_store  -c "${QUERY}"  >> /backups/CCD/mi_data.csv

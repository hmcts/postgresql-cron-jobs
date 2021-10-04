#!/bin/bash
###

  QUERY=$(cat <<EOF
COPY (SELECT now()
) TO STDOUT WITH CSV HEADER
EOF
)
psql -h dev-ops-db-restore.postgres.database.azure.com -p 5432 -U devopsadmin@dev-ops-db-restore -d ccd_data_store -c "${QUERY}"  >> /tmp/bob.txt

#!/bin/bash
cat <<EOF
COPY (
  SELECT count(*)
  FROM   individual_requests
  WHERE  request_status = 'Received'
  AND    date_trunc('day', created_date) < CURRENT_DATE
) TO STDOUT;
EOF
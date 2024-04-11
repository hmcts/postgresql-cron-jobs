#!/bin/bash
cat <<EOF
COPY (
  SELECT   TO_CHAR(created_date, 'DD-MON-YY HH24:MI:SS')
  ,        TO_CHAR(updated_date, 'DD-MON-YY HH24:MI:SS')
  ,        sdt_request_reference
  ,        request_status
  ,        request_type
  FROM     individual_requests
  WHERE    created_date > CURRENT_TIMESTAMP - INTERVAL '1 day'
  ORDER BY created_date DESC
  LIMIT    5
) TO STDOUT WITH CSV;
EOF
#!/bin/bash
cat <<EOF
COPY (
  SELECT   TO_CHAR(created_date, 'DD-MON-YY HH24:MI:SS')
  ,        sdt_request_reference
  ,        request_status
  ,        request_type
  FROM     individual_requests
  WHERE    dead_letter = true
  ORDER BY created_date
) TO STDOUT WITH CSV;
EOF
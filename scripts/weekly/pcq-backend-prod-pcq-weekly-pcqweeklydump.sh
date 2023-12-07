#!/bin/bash
cat <<EOF
COPY (
 SELECT * FROM protected_characteristics WHERE completed_date >= '20231120 00:00:00' AND completed_date < '20231204 00:00:00' ORDER BY completed_date) TO STDOUT with csv header ;
EOF

#!/bin/bash
DAYSAGO=$(date -d "9 days ago" '+%Y%m%d 00:00:00')
cat <<EOF
COPY (
 SELECT * FROM protected_characteristics WHERE completed_date >= '${DAYSAGO}' ORDER BY completed_date) TO STDOUT with csv header ;
EOF

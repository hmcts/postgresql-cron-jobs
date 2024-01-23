cat <<EOF
DAYSAGO=$(date -d "8 days ago" '+%Y%m%d 00:00:00')
COPY (
 SELECT * FROM protected_characteristics WHERE completed_date >= '${DAYSAGO}' ORDER BY completed_date) TO STDOUT with csv header ;
EOF

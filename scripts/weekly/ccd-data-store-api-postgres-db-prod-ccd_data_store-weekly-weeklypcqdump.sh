cat <<EOF
COPY (
 SELECT * FROM protected_characteristics WHERE completed_date >= '${DAYSAGO}' ORDER BY completed_date) TO STDOUT with csv header ;
EOF
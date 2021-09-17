#!/bin/bash
cat <<EOF
COPY (
SELECT servicename, action, count(id) AS "Number of Documents Accessed" FROM auditentry GROUP BY 1,2 order by 2,3) TO STDOUT WITH CSV HEADER
EOF
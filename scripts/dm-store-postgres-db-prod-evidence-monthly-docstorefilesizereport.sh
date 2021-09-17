#!/bin/bash
cat <<EOF
COPY (
SELECT (CASE     WHEN "size" BETWEEN 0             AND 999999         THEN '0-1MB'
                 WHEN "size" BETWEEN 1000000     AND 4999999     THEN '1-5MB'
                 WHEN "size" BETWEEN 5000000     AND 9999999     THEN '5-10MB'
                 WHEN "size" BETWEEN 10000000     AND 24999999     THEN '10-25MB'
                 WHEN "size" BETWEEN 25000000     AND 49999999     THEN '25-50MB'
                 WHEN "size" BETWEEN 50000000     AND 99999999     THEN '50-100MB'
                 WHEN "size" BETWEEN 100000000     AND 249999999     THEN '100-250MB'
                 WHEN "size" >                        250000000     THEN '250MB+'
        END) AS "SIZE RANGE", count( * ) AS "TOTAL"
FROM documentcontentversion
GROUP BY "SIZE RANGE"
ORDER BY max("size") DESC) TO STDOUT WITH CSV HEADER
EOF
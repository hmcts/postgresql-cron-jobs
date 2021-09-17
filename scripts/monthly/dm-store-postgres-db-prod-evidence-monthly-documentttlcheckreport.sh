#!/bin/bash
cat <<EOF
COPY (
select createdbyservice, deleted, harddeleted, extract(year from ttl) || '-' || extract(month from ttl) as year_month, count ( * )
from storeddocument
where ttl is not null
group by createdbyservice, deleted, harddeleted, year_month
order by 4 desc) TO STDOUT WITH CSV HEADER ;
EOF
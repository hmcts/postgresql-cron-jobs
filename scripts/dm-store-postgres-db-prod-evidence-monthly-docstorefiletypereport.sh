#!/bin/bash
cat <<EOF
COPY (
SELECT mimetype, SUBSTRING(UPPER(originaldocumentname) from '\.(\w+)$') as filetype, count(*)
FROM public.documentcontentversion
group by 1, 2
order by 3 desc) TO STDOUT WITH CSV HEADER
EOF
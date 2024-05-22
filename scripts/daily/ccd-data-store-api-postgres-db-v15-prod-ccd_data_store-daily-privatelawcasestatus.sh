#!/bin/bash
cat <<EOF
COPY (
SELECT reference as "Case number",  data -> 'courtName' as "Court name", data -> 'caseTypeOfApplication' as "Type of application",
data->'familymanCaseNumber' as "Family man ID", data -> 'dateSubmitted' as "Date submitted",
data->'caseStatus'-> 'state' as "State"
from case_data where case_type_id='PRLAPPS' and jurisdiction='PRIVATELAW'
and TO_DATE(data ->> 'dateSubmitted','YYYY-MM-DD') = CURRENT_DATE order by data -> 'dateSubmitted' desc;
EOF
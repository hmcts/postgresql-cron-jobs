#!/bin/bash

cat <<EOF
COPY (
select
reference,
state,
data ->>'hearingCentre' AS hearing_centre,
data ->>'ariaListingReference' AS listing_Reference,
data ->>'appealReferenceNumber' AS SC_number,
data ->>'isDecisionAllowed' AS decision_outcome,
data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded
from
case_data
where case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7)
ORDER BY dateUploaded DESC
) TO STDOUT WITH CSV HEADER
EOF
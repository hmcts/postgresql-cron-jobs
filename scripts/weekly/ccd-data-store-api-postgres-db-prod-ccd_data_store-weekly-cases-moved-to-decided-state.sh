cat <<EOF
COPY (
select
case.reference,
case.state,
case.data ->>'hearingCentre' AS hearing_centre,
case.data ->>'ariaListingReference' AS listing_Reference,
case.data ->>'appealReferenceNumber' AS SC_number,
case.data ->>'isDecisionAllowed' AS decision_outcome,
case.data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded' as dateUploaded
from
case_data case
where case_type_id = 'Asylum' AND jurisdiction = 'IA' and state ='decided' and DATE(data -> 'finalDecisionAndReasonsDocuments' -> 0 -> 'value' ->> 'dateUploaded') > (CURRENT_DATE - 7)
ORDER BY dateUploaded DESC
) TO STDOUT WITH CSV HEADER
EOF
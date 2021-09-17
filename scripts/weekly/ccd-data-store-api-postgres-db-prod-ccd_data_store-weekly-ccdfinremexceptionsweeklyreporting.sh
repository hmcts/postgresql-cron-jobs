#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id AS case_metadata_event_id,
CE.case_data_id AS ce_case_data_id,
CE.created_date AS ce_created_date,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
trim(CE.data ->> 'journeyClassification') AS CE_JOURNEYCLASSIFICATION,
trim(CE.data ->> 'deliveryDate') AS CE_DELIVERYDATE,
trim(CE.data ->> 'openingDate') AS CE_OPENINGDATE,
trim(CE.data ->> 'attachToCaseReference') AS CE_ATTACHTOCASEREFERENCE,
trim(CE.data ->> 'caseReference') AS CE_CASEREFERENCE,
trim(CE.data ->> 'formType') AS CE_FORMTYPE,
trim(CE.data ->> 'envelopeId') AS CE_ENVELOPEID,
trim(CE.data ->> 'awaitingPaymentDCNProcessing') AS CE_AWAITINGPAYMENTDCNPROCSSNG,
trim(CE.data ->> 'containsPayments') AS CE_CONTAINSPAYMENTS,
trim(CE.data ->> 'envelopeCaseReference') AS CE_ENVELOPECASEREFERENCE,
trim(CE.data ->> 'envelopeLegacyCaseReference') AS CE_ENVELOPELEGACYCASEREF
FROM case_event CE
WHERE CE.case_type_id = 'FINREM_ExceptionRecord'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF

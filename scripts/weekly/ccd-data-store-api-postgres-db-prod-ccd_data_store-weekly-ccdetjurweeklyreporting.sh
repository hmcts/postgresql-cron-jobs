#!/bin/bash
cat <<EOF
COPY (
SELECT * FROM
(SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
CE.case_data_id        AS CE_CASE_DATA_ID,
CE.ID as CE_ID,
CE.CREATED_DATE as CE_CREATED_DATE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{id}' AS CE_JURISDICTION_ID,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,juridictionCodesList}' AS CE_JURISDICTION_CODE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,judgmentOutcome}' AS CE_JUDGMENT_OUTCOME,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,date_judgment_made}' AS DATE_JUDGMENT_MADE,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,liability_optional}' AS LIABILITY_OPTIONAL,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,date_judgment_sent}' AS DATE_JUDJMENT_SENT,
jsonb_array_elements(CE.data->'jurCodesCollection')#>'{value,hearing_number}' AS HEARING_NUMBER
FROM case_event CE
where ce.id = (select max(b.id) from case_event b where b.case_data_id = ce.case_data_id)
AND CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date) a
Where CE_JURISDICTION_ID is not null
) TO STDOUT WITH CSV HEADER
EOF
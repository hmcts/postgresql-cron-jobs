#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS EXTRACTION_DATE,
CE.id                  AS CASE_METADATA_EVENT_ID,
CE.case_data_id        AS CE_CASE_DATA_ID,
CE.created_date        AS CE_CREATED_DATE,
trim(CE.case_type_id)  AS CE_CASE_TYPE_ID,
CE.case_type_version   AS CE_CASE_TYPE_VERSION,
trim(CE.data ->>'caseType') AS ce_case_type,
trim(CE.data ->>'receiptDate') AS ce_receipt_date,
trim(CE.data ->>'positionType') AS ce_position_type,
trim(CE.data ->>'multipleReference') AS ce_multiple_ref,
trim(CE.data ->>'ethosCaseReference') AS ce_ethos_case_ref,
trim(CE.data ->>'managingOffice') AS ce_managing_office,
trim(CE.data ->>'claimant_TypeOfClaimant') AS ce_claimant_type,
trim(CE.data ->>'claimantRepresentedQuestion') AS ce_claimant_represented,
trim(CE.data ->>'jurCodesCollection') AS ce_jurisdictions,
trim(CE.data ->>'leadClaimant') AS ce_lead_claimant,
trim(CE.data ->'preAcceptCase' ->>'dateAccepted') AS ce_date_accepted,
trim(CE.data ->>'judgementCollection') AS ce_judgment_collection,
trim(CE.data ->>'hearingCollection') AS ce_hearing_collection,
TRIM(ce.data ->> 'conciliationTrack') AS ce_conciliation_track,
TRIM(ce.data ->> 'dateToPosition') AS ce_date_to_position,
trim(CE.data -> 'representativeClaimantType' ->> 'representative_occupation') AS ce_claimant_repr_occuptn,
trim(CE.data #>> '{repCollection, 0, value, representative_occupation}') AS ce_first_resp_repr_occuptn
FROM case_event CE
WHERE CE.case_type_id IN ( 'Bristol','Leeds','LondonCentral','LondonEast','LondonSouth','Manchester','MidlandsEast','MidlandsWest','Newcastle','Scotland','Wales','Watford' )
AND CE.created_date >= (current_date-8 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date
) TO STDOUT WITH CSV HEADER
EOF

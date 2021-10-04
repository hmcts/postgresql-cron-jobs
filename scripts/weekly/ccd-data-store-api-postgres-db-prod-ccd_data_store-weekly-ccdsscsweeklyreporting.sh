cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id			AS case_metadata_event_id,
CE.case_data_id		AS ce_case_data_id,
CE.created_date		AS ce_created_date,
trim(CE.case_type_id)	AS ce_case_type_id,
CE.case_type_version	AS ce_case_type_version,
trim(CE.data ->> 'caseReference') AS CE_BEN_CASE_REF,
trim(CE.data ->> 'caseCreated') AS CE_CASE_CREATED_DATE,
trim(CE.data -> 'appeal' ->> 'receivedVia') AS CE_RECEIVED_VIA,
trim(CE.data -> 'appeal' ->> 'hearingType') AS CE_HEARING_TYPE,
trim(CE.data -> 'appeal' -> 'rep' ->> 'hasRepresentative') AS CE_HAS_REPR,
trim(CE.data -> 'regionalProcessingCenter' ->> 'name') AS CE_REGIONAL_CENTRE,
trim(CE.data ->> 'outcome') AS CE_CASE_OUTCOME,
trim(CE.data ->> 'caseCode') AS CE_CASE_CODE,
trim(CE.data ->> 'directionType') AS CE_DIRECTION_TYPE,
trim(CE.data ->> 'decisionType') AS CE_DECISION_TYPE,
trim(CE.data ->> 'dwpState') AS CE_DWP_STATE,
trim(CE.data ->> 'dwpRegionalCentre') AS CE_DWP_REGIONAL_CENTRE,
trim(CE.data ->> 'createdInGapsFrom') AS CE_GAPS2_ENTRY_POINT,
trim(CE.data ->> 'interlocReviewState') AS CE_INTERLOC_REVIEW_STATE,
trim(CE.data ->> 'scannedDocuments') AS CE_SCANNED_DOCUMENTS_COLL,
trim(CE.data ->> 'dateSentToDwp') AS CE_DATE_SENT_TO_DWP,
trim(CE.data ->> 'reinstatementRegistered') AS CE_REINSTMNT_REGSTRD_DATE,
trim(CE.data ->> 'reinstatementOutcome') AS CE_REINSTMNT_OUTCOME,
trim(CE.data ->> 'urgentHearingRegistered') AS CE_URGNT_HRNG_REGSTRD_DATE,
trim(CE.data ->> 'urgentHearingOutcome') AS CE_URGNT_HRNG_OUTCOME
FROM case_event CE
WHERE CE.case_type_id = 'Benefit'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
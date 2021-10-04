#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id AS case_metadata_event_id,
CE.case_data_id AS ce_case_data_id,
CE.created_date AS ce_created_date,
trim(CE.case_type_id) AS ce_case_type_id,
CE.case_type_version AS ce_case_type_version,
trim(CE.data ->> 'issueDate') AS CE_ISSUED_DATE,
trim(CE.data ->> 'fastTrackDecision') AS CE_FAST_TRACK_DECISION,
trim(CE.data ->> 'divorceStageReached') AS CE_DIVORCE_STAGE_REACHED,
trim(CE.data ->> 'applicantAttendedMIAM') AS CE_APPLICANT_ATTENDED_MIAM,
TRIM(ce.data ->> 'paperApplication') AS ce_paper_application,
trim(CE.data ->> 'divorceCaseNumber') AS CE_DIVORCE_CASE_NUM,
TRIM(ce.data ->> 'applicantRepresented') AS ce_applicant_represented,
TRIM(ce.data ->> 'respondentRepresented') AS ce_respondent_represented,
TRIM(ce.data ->> 'regionList') AS ce_region,
TRIM(ce.data ->> 'nameOfCourtDivorceCentre') AS ce_divorce_centre,
TRIM(ce.data ->> 'divorcePetitionIssuedDate') AS ce_divorce_issue_date,
TRIM(ce.data ->> 'natureOfApplicationChecklist') AS ce_nature_of_application,
TRIM(ce.data ->> 'additionalPropertyOrderDecision') AS ce_additional_property_order,
TRIM(ce.data ->> 'divorceDecreeNisiDate') AS ce_decree_nisi_date,
TRIM(ce.data ->> 'divorceDecreeAbsoluteDate') AS ce_decree_absolute_date,
TRIM(ce.data ->> 'midlandsFRCList') AS ce_midlands_frc,
TRIM(ce.data ->> 'londonFRCList') AS ce_london_frc,
TRIM(ce.data ->> 'northWestFRCList') AS ce_north_west_frc,
TRIM(ce.data ->> 'northEastFRCList') AS ce_north_east_frc,
TRIM(ce.data ->> 'southEastFRCList') AS ce_south_east_frc,
TRIM(ce.data ->> 'walesFRCList') AS ce_wales_frc,
TRIM(ce.data ->> 'southWestFRCList') AS ce_south_west_frc,
TRIM(ce.data ->> 'listedCourtName') AS ce_listed_court_name,
TRIM(ce.data ->> 'PBAPaymentReference') AS ce_pba_payment_ref,
TRIM(ce.data ->> 'helpWithFeesQuestion') AS ce_hwf_question,
TRIM(ce.data ->> 'HWFNumber') AS ce_hwf_number,
TRIM(ce.data ->> 'hearingDate') AS ce_hearing_date,
TRIM(ce.data ->> 'hearingType') AS ce_hearing_type,
TRIM(ce.data ->> 'generalApplicationOutcome') AS ce_general_application_outcome,
ce.data ->> 'draftDirectionDetailsCollectionRO' AS ce_draft_directions_coll
FROM case_event CE
WHERE CE.case_type_id = 'FinancialRemedyContested'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
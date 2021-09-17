#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id			AS case_metadata_event_id,
CE.case_data_id		AS ce_case_data_id,
CE.created_date		AS ce_created_date,
trim(CE.case_type_id)	AS ce_case_type_id,
CE.case_type_version	AS ce_case_type_version,
trim(CE.data ->>'applicationType') AS ce_app_type,
trim(CE.data ->>'applicationSubmittedDate') AS ce_app_sub_date,
trim(CE.data ->>'registryLocation') AS ce_reg_location,
trim(CE.data ->>'willExists') AS ce_will_exists,
trim(CE.data ->>'ihtNetValue') AS ce_iht_net_value,
trim(CE.data ->>'ihtGrossValue') AS ce_iht_gross_value,
trim(CE.data ->>'deceasedDateOfDeath') AS ce_deceased_dod,
trim(CE.data ->>'deceasedAnyOtherNames') AS ce_deceased_other_names,
trim(CE.data ->>'boCaseStopReasonList') AS ce_case_stop_reason,
jsonb_array_length(CE.data ->'boCaseStopReasonList') AS ce_case_stop_reason_cnt,
trim(CE.data ->>'caseType') AS ce_gor_case_type,
trim(CE.data ->>'paperForm') AS ce_paperform_ind,
trim(CE.data ->>'grantIssuedDate') AS ce_grantissued_date,
trim(CE.data ->>'recordId') AS ce_leg_record_id,
trim(CE.data ->>'latestGrantReissueDate') AS ce_lat_grnt_reiss_date,
trim(CE.data ->>'reissueReasonNotation') AS ce_reiss_rea_not,
trim(CE.data ->>'languagePreferenceWelsh') AS ce_welsh_lang_pref,
TRIM(CE.data ->> 'primaryApplicantAddress') AS primary_applicant_addr,
TRIM(CE.data ->> 'evidenceHandled') AS ce_evidence_handled
FROM case_event CE
WHERE CE.case_type_id = 'GrantOfRepresentation'
AND CE.created_date >= (current_date-8 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(current_timestamp, 'YYYYMMDD-HH24MI') AS extraction_date,
CE.id                                      AS case_metadata_event_id,
CE.case_data_id                               AS ce_case_data_id,
CE.created_date                              AS ce_created_date,
trim(CE.case_type_id)   AS ce_case_type_id,
CE.case_type_version    AS ce_case_type_version,
trim(CE.data ->> 'issueDate') AS CE_ISSUED_DATE,
trim(CE.data ->> 'orderDirectionDate') AS CE_ORDER_DATE,
trim(CE.data ->> 'divorceCaseNumber') AS CE_DIVORCE_CASE_NUM,
trim(CE.data ->> 'natureOfApplication2') AS CE_ORDER_TYPES,
trim(CE.data ->> 'orderDirectionJudge') AS CE_JUDGE_TYPE,
TRIM(ce.data ->> 'applicantRepresented') AS ce_applicant_represented,
TRIM(ce.data ->> 'appRespondentRep') AS ce_respondent_represented,
TRIM(ce.data ->> 'paperApplication') AS ce_paper_application,
TRIM(ce.data ->> 'regionList') AS ce_region,
TRIM(ce.data ->> 'assignedToJudge') AS ce_assigned_to_judge
FROM case_event CE
WHERE CE.case_type_id = 'FinancialRemedyMVP2'
AND CE.created_date >= (current_date-7 + time '00:00')
AND CE.created_date < (current_date + time '00:00')
ORDER BY CE.created_date ASC
) TO STDOUT WITH CSV HEADER
EOF
#!/bin/bash
cat <<EOF
COPY (
SELECT to_char(CAST (ce.data ->> 'grantStoppedDate' AS DATE), 'DD/MM/YYYY')  AS date_of_stop,
trim(ce.data->>'registryLocation') AS registry,
case_stopped_lastweek.reference AS case_number,
CONCAT(ce.data ->> 'deceasedSurname', ' ',ce.data ->> 'deceasedForenames') AS full_name,
jsonb_array_elements(ce.data -> 'boCaseStopReasonList') -> 'value' ->> 'caseStopReason' AS stop_reason,
ce.user_first_name || ' ' || ce.user_last_name as author
FROM case_event as ce, (SELECT distinct cd.id as caseID, reference
                                FROM case_event as ce_stopped_lastweek INNER JOIN case_data cd ON cd.id = ce_stopped_lastweek.case_data_id AND cd.jurisdiction = 'PROBATE'
                                WHERE ce_stopped_lastweek.case_type_id = 'GrantOfRepresentation'
                                AND ce_stopped_lastweek.data #>> '{boCaseStopReasonList}' IS NOT NULL
                                AND ce_stopped_lastweek.event_id in ('boStopCase', 'boStopCaseForCaseMatchingForExamining','boStopCaseForRegistrarEscalations', 'boStopCaseForCasePrinted','boStopCaseForCaseMatching', 'boStopCaseForCaseCreated','boStopCaseForGrantReissueExamining', 'boStopCaseForGrantReissueMatching')
                                AND ce_stopped_lastweek.created_date between (current_date - 7 + time '00:00') and (current_date + time '00:00')
                                ) as case_stopped_lastweek
WHERE case_stopped_lastweek.caseID = ce.case_data_id
AND ce.case_type_id = 'GrantOfRepresentation'
AND ce.event_id in ('boStopCase', 'boStopCaseForCaseMatchingForExamining','boStopCaseForRegistrarEscalations', 'boStopCaseForCasePrinted','boStopCaseForCaseMatching', 'boStopCaseForCaseCreated','boStopCaseForGrantReissueExamining', 'boStopCaseForGrantReissueMatching')
AND ce.data #>> '{boCaseStopReasonList}' IS NOT NULL
ORDER BY 3,CAST (ce.data ->> 'grantStoppedDate' AS DATE)
) TO STDOUT WITH CSV HEADER ;
EOF
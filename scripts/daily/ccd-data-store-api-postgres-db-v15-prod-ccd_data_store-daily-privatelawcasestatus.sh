#!/bin/bash
cat <<EOF
COPY (
SELECT '"'||reference ||'"' as "Case number",
           data -> 'courtName' as "Court name",
           data -> 'caseTypeOfApplication' as "Type of application",
           data -> 'familymanCaseNumber' as "Family man ID",
           data -> 'dateSubmitted' as "Date submitted",
           data -> 'caseStatus' ->> 'state' as "State"
    FROM case_data
    WHERE case_type_id = 'PRLAPPS'
      AND jurisdiction = 'PRIVATELAW'
      AND data ->> 'dateSubmitted' >= '2024-04-10'
    ORDER BY data -> 'dateSubmitted' DESC
) to stdout with csv header;
EOF

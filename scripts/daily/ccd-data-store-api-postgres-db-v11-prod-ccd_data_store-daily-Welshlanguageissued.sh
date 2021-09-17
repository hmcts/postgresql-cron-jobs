#!/bin/bash
cat <<EOF
COPY (
SELECT cd.reference, ce.created_date AS event_date,cd.last_state_modified_date, ce.state_id, ce.event_name, ce.user_first_name,ce.user_last_name, cd.data->>'languagePreferenceWelsh' AS Welsh_Flag,cd.data->'appeal'->'appellant'->'name'->>'lastName'AS lastname, cd.data->'appeal'->'appellant'->'address'->>'postcode' AS postcode  FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE cd.case_type_id='Benefit' AND jurisdiction='SSCS' AND upper(cd.data->>'languagePreferenceWelsh')='YES' ORDER BY 1,2 desc) TO STDOUT with csv header ;
EOF
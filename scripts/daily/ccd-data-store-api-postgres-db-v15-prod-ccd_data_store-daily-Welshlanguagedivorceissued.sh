#!/bin/bash
cat <<EOF
COPY (
SELECT cd.reference, ce.created_date AS event_date,cd.last_state_modified_date, ce.state_id, ce.event_name, cd.data->>'D8DivorceUnit' AS D8DivorceUnit, cd.data->'D8PetitionerHomeAddress'->>'PostCode' AS D8PetitionerHomeAddress_postcode, ce.user_first_name,ce.user_last_name, cd.data->>'LanguagePreferenceWelsh' AS Welsh_Flag  FROM case_data cd JOIN case_event ce ON cd.id = ce.case_data_id WHERE cd.case_type_id='DIVORCE' AND upper(cd.data->>'LanguagePreferenceWelsh')='YES' ORDER BY 1,2 desc) TO STDOUT with csv header ;
EOF
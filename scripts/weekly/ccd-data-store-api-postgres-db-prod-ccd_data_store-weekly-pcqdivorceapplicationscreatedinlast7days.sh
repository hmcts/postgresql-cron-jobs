#!/bin/bash
cat <<EOF
COPY (
  select reference, created_date, state, data->>'PetitionerPcqId' AS  petitioner_pcqid, data->>'RespondentPcqId' AS respondent_pcqid, data->>'CoRespondentPcqId' AS co_respondent_pcqid from case_data WHERE case_type_id ='DIVORCE' AND jurisdiction = 'DIVORCE' and (data->>'PetitionerPcqId' IS NOT NULL OR data->>'RespondentPcqId' IS NOT NULL OR data->>'CoRespondentPcqId' IS NOT NULL AND created_date >= '${DAYSAGO}') ORDER BY 2) TO STDOUT with csv header ;
EOF
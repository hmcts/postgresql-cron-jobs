#!/bin/bash
cat <<EOF
COPY (
with eom_data as (SELECT data -> 'previousServiceCaseReference' as Claim_number
       ,data ->> 'caseName' as case_Name
       ,data ->> 'submitterEmail' as submitter_email
       ,data -> 'applicants' -> 0 -> 'value' -> 'partyDetail' -> 'idamId' as Claimant_IDAMID
       ,data -> 'applicants' -> 0 -> 'value' -> 'partyDetail' -> 'type' as Claimant_Type
       ,data -> 'applicants' -> 0 -> 'value' -> 'partyName' as Claimant
       ,data -> 'applicants' -> 0 -> 'value' -> 'partyDetail' -> 'emailAddress' as Claimant_Email
       ,data -> 'respondents' -> 0 -> 'value' -> 'partyDetail' -> 'idamId' as Defendant_IDAMID
       ,data -> 'respondents' -> 0 -> 'value' -> 'partyDetail' -> 'type' as Defendant_Type
       ,data -> 'respondents' -> 0 -> 'value' -> 'partyName' as Defendant
       ,data -> 'respondents' -> 0 -> 'value' -> 'partyDetail' -> 'emailAddress' as Defendant_Email
       ,last_state_modified_date
       ,state
FROM case_data cd
WHERE jurisdiction = 'CMC'
AND case_type_id = 'MoneyClaimCase'
AND data -> 'applicants' -> 0 -> 'value' -> 'partyDetail' ->> 'type' = 'INDIVIDUAL'
AND last_state_modified_date >= date_trunc('month', current_date) - INTERVAL '2' MONTH
AND last_state_modified_date < date_trunc('month', current_date)
)
select claim_number, case_name, submitter_email, claimant, defendant, last_state_modified_date, state
  from eom_data
 where claimant_idamid in (select claimant_idamid from eom_data group by claimant_idamid having count(claimant_idamid) >= 5)
 order by submitter_email, claimant_idamid, last_state_modified_date) to stdout with csv header;
EOF

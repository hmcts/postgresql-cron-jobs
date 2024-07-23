#!/bin/bash
cat <<EOF
COPY (
SELECT temp.reference, temp.state, ce.created_date, ce.event_name
FROM
(SELECT cd.reference, cd.state, MAX(ce.id) last_event_id
FROM case_data cd,
case_event ce
WHERE cd.id = ce.case_data_id
AND cd.jurisdiction = 'PROBATE'
AND cd.case_type_id = 'GrantOfRepresentation'
AND ce.case_type_id = 'GrantOfRepresentation'
AND cd.last_modified >= now() - INTERVAL '185 day'
AND ce.created_date >= now() - INTERVAL '365 day'
AND ce.event_id NOT IN ('boHistoryCorrection', 'boCorrection')
AND cd.state IN (
 'BOCaseMatchingIssueGrant' ,
 'BOCaseQA' ,
 'BOReadyToIssue' ,
 'BORegistrarEscalation' ,
 'BOCaseStopped' ,
 'CasePrinted' ,
 'BOSotGenerated' ,
 'BORedecNotificationSent' ,
 'BOCaseStoppedAwaitRedec' ,
 'BOCaseStoppedReissue' ,
 'BOCaseMatchingReissue' ,
 'BOExaminingReissue' ,
 'BOCaseImported' ,
 'BOCaveatPermenant' ,
 'BOCaseWorkerEscalation' ,
 'BOPostGrantIssued')
AND cd.data ->> 'applicationSubmittedDate' IS NOT NULL
GROUP BY cd.reference, cd.state) temp
JOIN case_event ce
ON temp.last_event_id = ce.id
WHERE ce.created_date <= now() - INTERVAL '6 month'
ORDER BY 1) to stdout with csv header;
EOF
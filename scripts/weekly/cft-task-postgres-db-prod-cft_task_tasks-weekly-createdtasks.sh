#!/bin/bash
cat <<EOF
COPY (SELECT t.created AS created, t.case_id,t.task_id,t.role_category,t.task_name,t.task_type,t.location_name,t.due_date_time,t.assignment_expiry,t.state FROM cft_task_db.tasks t where t.created >= (current_date-7 + time '00:00:00.000000') ORDER BY t.created) TO STDOUT WITH CSV HEADER;
EOF

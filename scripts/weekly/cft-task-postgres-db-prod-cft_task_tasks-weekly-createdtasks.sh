cat <<EOF
COPY (
SELECT t.created AS created,
t.case_id,
t.task_id,
t.role_category,
t.task_name,
t.task_type,
t.location_name,
t.due_date_time,
t.assignment_expiry,
t.state
FROM cft_task_db.tasks t
where t.created >= (current_date-7 + time '00:00')
AND t.created < (current_date + time '00:00')
ORDER BY t.created ASC
) TO STDOUT WITH CSV HEADER
EOF

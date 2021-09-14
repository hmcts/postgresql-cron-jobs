----
-- RDM-6538 Link cases to a new user from an old user
-- 
-- 1. Update variables on lines 10 and 13
-- 2. Run against ccd_data e.g.
--      psql -h <host> -p <port> -d ccd_data -U ccd -f update_case_user_links.sql
----
-- Original (deleted) user ID
\set old_user_id '9da0ff25-ee38-441e-b434-e0df73ae305b'
-- New user ID
\set new_user_id 'e88c9df7-dc29-4bb1-8dda-5b2d073a10e3'
---
-- case_users
---
\echo 'Linking cases of OLD user id' :'old_user_id' 'to NEW user id' :'new_user_id'
UPDATE case_users SET user_id = :'new_user_id' WHERE user_id = :'old_user_id';
---
-- case_users_audit
---
\echo 'Inserting case_users_audit records'
INSERT INTO case_users_audit (id, case_data_id, user_id, changed_by_id, changed_at, action, case_role)
VALUES (DEFAULT, UNNEST(ARRAY(SELECT case_data_id FROM case_users_audit WHERE user_id = :'old_user_id' AND action = 'GRANT')), :'new_user_id', :'new_user_id', DEFAULT, 'GRANT', '[CREATOR]');
INSERT INTO case_users_audit (id, case_data_id, user_id, changed_by_id, changed_at, action, case_role)
VALUES (DEFAULT, UNNEST(ARRAY(SELECT case_data_id FROM case_users_audit WHERE user_id = :'old_user_id' AND action = 'REVOKE')), :'new_user_id', :'new_user_id', DEFAULT, 'REVOKE', '[CREATOR]');
\echo 'Updates complete.'

CREATE INDEX CONCURRENTLY idx_case_data_pl_familyManCaseNumber ON public.case_data USING btree (btrim(upper((data #>> '{familyManCaseNumber}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_pl_dateAndTimeSubmitted ON public.case_data USING btree (btrim(upper((data #>> '{dateAndTimeSubmitted}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_pr_journeyClassification ON public.case_data USING btree (btrim(upper((data #>> '{journeyClassification}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_pr_caseType ON public.case_data USING btree (btrim(upper((data #>> '{caseType}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_pr_casePrinted ON public.case_data USING btree (btrim(upper((data #>> '{casePrinted}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_pr_expiryDate ON public.case_data USING btree (btrim(upper((data #>> '{expiryDate}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_user_user_id ON case_users (user_id);

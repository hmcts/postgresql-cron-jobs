CREATE INDEX CONCURRENTLY idx_case_data_sscs_appellant_dob ON public.case_data USING btree (btrim(upper((data #>> '{appeal,appellant,identity,dob}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_attachToCaseReference ON public.case_data USING btree (btrim(upper((data #>> '{attachToCaseReference}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_dateSentToDwp ON public.case_data USING btree (btrim(upper((data #>> '{dateSentToDwp}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_directionDueDate ON public.case_data USING btree (btrim(upper((data #>> '{directionDueDate}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_appeal,hearingType ON public.case_data USING btree (btrim(upper((data #>> '{appeal,hearingType}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_surname ON public.case_data USING btree (btrim(upper((data #>> '{surname}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_urgentCase ON public.case_data USING btree (btrim(upper((data #>> '{urgentCase}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_sscs_createdInGapsFrom ON public.case_data USING btree (btrim(upper((data #>> '{createdInGapsFrom}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_last_state_modified_date ON case_data (last_state_modified_date);

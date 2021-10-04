CREATE INDEX CONCURRENTLY idx_case_data_IA_appealReferenceNumber ON public.case_data USING btree (btrim(upper((data #>> '{appealReferenceNumber}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_IA_appellantDateOfBirth ON public.case_data USING btree (btrim(upper((data #>> '{appellantDateOfBirth}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_IA_appellantNameForDisplay ON public.case_data USING btree (btrim(upper((data #>> '{appellantNameForDisplay}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_IA_searchPostcode ON public.case_data USING btree (btrim(upper((data #>> '{searchPostcode}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_IA_legalRepReferenceNumber ON public.case_data USING btree (btrim(upper((data #>> '{legalRepReferenceNumber}'::text[]))));
CREATE INDEX CONCURRENTLY idx_case_data_IA_homeOfficeReferenceNumber ON public.case_data USING btree (btrim(upper((data #>> '{homeOfficeReferenceNumber}'::text[]))));

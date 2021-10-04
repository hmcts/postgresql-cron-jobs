--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.10
-- Dumped by pg_dump version 9.6.8

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: alliu; Type: TABLE DATA; Schema: public; Owner: probateman_user
--

COPY public.alliu (caveat_number, probate_number, probate_version, deceased_id, deceased_forenames, deceased_surname, date_of_birth, date_of_death1, alias_names, ccd_case_no, id, caveat_type, caveat_date_of_entry, cav_date_last_extended, cav_expiry_date, cav_withdrawn_date, caveator_title, caveator_honours, caveator_forenames, caveator_surname, cav_solicitor_name, cav_service_address, cav_dx_number, cav_dx_exchange, caveat_text, caveat_event_text, dnm_ind, last_modified) FROM stdin;
95523	\N	\N	7419228	DOREEN	JAUNS	\N	2018-08-23	\N	\N	72652	Caveat	2018-09-25	\N	\N	2019-02-04	\N	\N	ANDREW SIMON	JAUNS	\N	11 Crispin Close Locks Heath Southampton SO31 6TD	\N	\N	25-SEP-2018~~~04-FEB-2019~~~ANDREW SIMON~JAUNS~~11 Crispin Close Locks Heath Southampton SO31 6TD~~~524~DSI_ANC~04-FEB-2019~~0~0~Caveat~KCO_524	139892~04-FEB-2019~~DSI_ANC~aff of service recd and accepted~~516~Removal|138995~07-JAN-2019~~CBA_ANC~Warning sealed~~516~Warning	\N	2019-02-09 02:34:50.600508
96871	\N	\N	7487541	KATHERINE MARIA	FILIPOVITCH	\N	2016-09-22	\N	\N	12130	Caveat	2018-12-11	\N	\N	\N	\N	\N	ADRIAN	WATKINS	BUSS MURTON (EBW/RKB/F105760005)	Wellington Gate 7-9 Church Road Tunbridge Wells Kent TN1 1HT	3913	TUNBRIDGE WELLS	11-DEC-2018~~~~~~ADRIAN~WATKINS~BUSS MURTON (EBW/RKB/F105760005)~Wellington Gate 7-9 Church Road Tunbridge Wells Kent TN1 1HT~3913~TUNBRIDGE WELLS~513~CHU_ANC~08-FEB-2019~3913~513~0~Caveat~LAT_513	139448~22-JAN-2019~~CBA_ANC~Warning sealed~~516~Warning|140069~08-FEB-2019~~CHU_ANC~file no. 37/19~~516~Appearance	\N	2019-02-09 02:34:50.600508
96904	\N	\N	7489004	ANDREW HAYES	DUNLOP	\N	2018-10-07	DUNLOP~~ANDREW~~R~	\N	84922	Caveat	2018-12-12	\N	\N	2019-02-08	\N	\N	CHARLES TREVOR	DUNLOP	Dawson And Burgess Solicitors	3 South Parade Hall Cross Hill Doncaster DN1 2DZ	\N	\N	12-DEC-2018~~~08-FEB-2019~~~CHARLES TREVOR~DUNLOP~Dawson And Burgess Solicitors~3 South Parade Hall Cross Hill Doncaster DN1 2DZ~~~516~CHU_516~08-FEB-2019~~0~0~Caveat~LOB_ANC	140062~08-FEB-2019~~CHU_516~~~516~Withdrawal	\N	2019-02-09 02:34:50.600508
97644	\N	\N	7526130	LILIAN IRIS	KNOBEL	\N	2015-04-12	KNOBEL~~LILIAN IRIS~~~7512689	\N	12231	Writ	2019-01-30	\N	\N	\N	\N	\N	KNOBEL V KNOBEL	HC-2017-002442	Chancery Masters Appointments	RCJ 7 Rolls Buildings Fetter Lane London EC4A 1NL	160040	STRAND 4	30-JAN-2019~~~~~~KNOBEL V KNOBEL~HC-2017-002442~Chancery Masters Appointments~RCJ 7 Rolls Buildings Fetter Lane London EC4A 1NL~160040~STRAND 4~516~~~~0~0~Writ~CDE_ANC	139749~30-JAN-2019~~CDE_ANC~file no 21/19~~516~Other|139751~30-JAN-2019~~CDE_ANC~o/will as above returned to chancery for marking as per order~~516~Other|139750~30-JAN-2019~~CDE_ANC~final order and o/will dated 21/1/1994 rec from chancery~~516~Other|139915~05-FEB-2019~~CDE_ANC~email from Newcastle DPR replied and advised re above~~516~Other	\N	2019-02-09 02:34:50.600508
\.


--
-- PostgreSQL database dump complete
--


--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.3
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: regions; Type: TABLE; Schema: public; Owner: db
--

CREATE TABLE regions (
    id uuid NOT NULL,
    name character varying(50) NOT NULL,
    inserted_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    koatuu character varying(10)
);


ALTER TABLE regions OWNER TO db;

--
-- Data for Name: regions; Type: TABLE DATA; Schema: public; Owner: db
--

COPY regions (id, name, inserted_at, updated_at, koatuu) FROM stdin;
b392aad2-988b-4452-851c-766d48fc94c6	АВТОНОМНА РЕСПУБЛІКА КРИМ	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	0100000000
c4c0f907-8b60-483e-bbf6-dfb34ab91574	ВІННИЦЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	0500000000
45311788-3735-4ccf-884c-409c089f3a45	ДНІПРОПЕТРОВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	1200000000
27b0197d-f470-4b2c-af27-4d82e953db9d	ДОНЕЦЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	1400000000
0cbaccf9-77e2-48a4-94d3-ad3737140476	ЖИТОМИРСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	1800000000
9ff97849-ea3b-449a-9a2d-f7de4c3e9559	ЗАКАРПАТСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	2100000000
00eb9de4-508d-4219-bfc8-496238570dfd	ЗАПОРІЗЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	2300000000
4fc7d2f2-c61a-4533-a1a9-62480c80e263	ІВАНО-ФРАНКІВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	2600000000
c0607c50-2dde-4c79-8ec9-696836a99a18	КИЇВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	3200000000
bfc84d7a-6487-4ae4-93b6-026182ff1238	КІРОВОГРАДСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	3500000000
616f1acc-7a4e-4d03-9a03-5ab3e372578f	ЛУГАНСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	4400000000
1718a2a9-46cb-4f53-a3eb-2b341f7bb034	ЛЬВІВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	4600000000
3f766fcd-8f57-49b1-8c63-0ecf6a1c73d7	МИКОЛАЇВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	4800000000
b11b31ba-38d9-4a2c-818d-6a1a980998cf	ОДЕСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	5100000000
e73779f5-5336-4f14-8351-0938bb412571	ПОЛТАВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	5300000000
23a4fa72-d570-4f19-b8f3-89ac42341a47	РІВНЕНСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	5600000000
23b8090d-9efa-4431-b63a-3f45559eee2c	СУМСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	5900000000
d19e3326-407e-4323-a5a3-e43f574d63cc	ТЕРНОПІЛЬСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	6100000000
cfb02075-fab4-4fb1-9a1d-2de9bd3c698a	ХАРКІВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	6300000000
6f985e33-182f-4aa2-acfc-8bf34702bb85	ХЕРСОНСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	6500000000
39654298-c513-406c-ab27-4adde3921bb1	ХМЕЛЬНИЦЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	6800000000
c55239e7-8c73-425b-a0ef-70466a250581	ЧЕРКАСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	7100000000
785cb11c-7efb-4599-b613-e19c4c91b289	ЧЕРНІВЕЦЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	7300000000
d5c669ff-0af8-4dd3-b683-b7d405b071b2	ЧЕРНІГІВСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	7400000000
1a0a5d1f-06fb-4c93-b9a5-e9eaadea664e	М.КИЇВ	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	8000000000
99310bc4-ac7c-4f1f-bc29-b3ae25bd96bc	М.СЕВАСТОПОЛЬ	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	8500000000
09a33c98-9a5c-447a-8493-da8fcecb6873	ВОЛИНСЬКА	2017-06-09 14:45:07.381	2017-06-09 14:45:07.381	0700000000
\.


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: db
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- PostgreSQL database dump complete
--


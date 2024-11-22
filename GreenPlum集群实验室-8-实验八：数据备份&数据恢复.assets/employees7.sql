--
-- Greenplum Database database dump
--

SET gp_default_storage_options = '';
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: employees7; Type: TABLE; Schema: public; Owner: gpadmin; Tablespace: 
--

CREATE TABLE public.employees7 (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    age integer NOT NULL,
    gender character(1) NOT NULL,
    department character varying(50) NOT NULL,
    hire_date date NOT NULL,
    birth_date date NOT NULL,
    address character varying(100) NOT NULL,
    salary integer NOT NULL
)
 DISTRIBUTED BY (id);


ALTER TABLE public.employees7 OWNER TO gpadmin;

--
-- Name: TABLE public.employees7 ; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON TABLE public.employees7 IS '员工信息表，包括姓名、年龄、性别、部门、入职日期、出生日期、地址和薪资等字段。';


--
-- Name: COLUMN employees7.name; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.name IS '员工姓名，以固定格式加随机数生成';


--
-- Name: COLUMN employees7.age; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.age IS '员工年龄，范围在 18 到 60 之间';


--
-- Name: COLUMN employees7.gender; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.gender IS '员工性别，M 代表男性，F 代表女性';


--
-- Name: COLUMN employees7.department; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.department IS '员工部门，如 HR、Engineering、Marketing、Sales';


--
-- Name: COLUMN employees7.hire_date; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.hire_date IS '员工入职日期，随机生成的日期';


--
-- Name: COLUMN employees7.birth_date; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.birth_date IS '员工出生日期，随机生成的日期';


--
-- Name: COLUMN employees7.address; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.address IS '员工地址，随机生成的地址信息';


--
-- Name: COLUMN employees7.salary; Type: COMMENT; Schema: public; Owner: gpadmin
--

COMMENT ON COLUMN public.employees7.salary IS '员工薪资，范围在 3000 到 50000 之间';


--
-- Name: employees7_id_seq; Type: SEQUENCE; Schema: public; Owner: gpadmin
--

CREATE SEQUENCE public.employees7_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.employees7_id_seq OWNER TO gpadmin;

--
-- Name: employees7_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: gpadmin
--

ALTER SEQUENCE public.employees7_id_seq OWNED BY public.employees7.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: gpadmin
--

ALTER TABLE ONLY public.employees7 ALTER COLUMN id SET DEFAULT nextval('public.employees7_id_seq'::regclass);


--
-- Data for Name: employees7; Type: TABLE DATA; Schema: public; Owner: gpadmin
--

COPY public.employees7 (id, name, age, gender, department, hire_date, birth_date, address, salary) FROM stdin;
34	员工_876	33	F	Marketing	2006-06-15	1998-05-22	北京市 随机街道33号	27892
15	员工_166	30	F	HR	2002-04-20	1982-11-23	上海市 随机街道95号	48015
56	员工_931	46	F	Engineering	2002-07-26	1968-08-01	北京市 随机街道65号	43576
55	员工_987	52	F	Marketing	2000-12-29	1970-12-21	北京市 随机街道88号	20858
1	员工_857	48	M	Sales	2003-11-13	1981-04-12	上海市 随机街道90号	4410
28	员工_297	52	F	Engineering	2004-01-11	1981-06-20	上海市 随机街道46号	39018
14	员工_17	23	F	HR	2005-09-08	1985-01-04	北京市 随机街道66号	13280
3	员工_629	52	F	HR	2006-10-21	1985-07-15	北京市 随机街道2号	25507
29	员工_770	18	F	Marketing	2004-12-21	1980-05-18	上海市 随机街道42号	30193
2	员工_92	30	F	Sales	2006-08-17	1996-12-17	北京市 随机街道30号	48223
27	员工_629	56	F	Marketing	2002-08-15	1994-12-17	北京市 随机街道88号	34601
7	员工_58	42	F	Sales	2009-04-05	1967-01-22	上海市 随机街道70号	47467
19	员工_964	20	M	HR	2006-02-02	1995-10-06	上海市 随机街道99号	35866
9	员工_213	39	F	Marketing	2005-07-28	1992-08-29	上海市 随机街道53号	27915
4	员工_839	22	F	Engineering	2002-03-17	1967-12-07	上海市 随机街道10号	27420
12	员工_161	44	M	HR	2009-05-29	1998-05-07	上海市 随机街道39号	14362
6	员工_948	50	F	HR	2004-07-25	1977-10-05	北京市 随机街道47号	45834
5	员工_536	34	M	HR	2000-10-17	1968-09-06	广州市 随机街道96号	47250
21	员工_584	56	M	Engineering	2002-11-01	1995-09-19	北京市 随机街道71号	20193
33	员工_159	54	F	Marketing	2001-04-21	1967-09-17	广州市 随机街道62号	3795
53	员工_410	41	F	HR	2007-12-25	1992-10-01	广州市 随机街道56号	23119
23	员工_380	45	M	Engineering	2002-11-08	1964-03-03	广州市 随机街道30号	4370
62	员工_377	50	M	HR	2007-05-01	1992-05-14	深圳市 随机街道12号	47408
70	员工_317	57	F	Marketing	2009-10-01	1976-10-20	上海市 随机街道98号	47545
50	员工_624	29	M	Engineering	2007-01-06	1969-06-26	北京市 随机街道22号	5406
75	员工_851	58	F	Engineering	2004-05-26	1986-11-25	广州市 随机街道82号	16045
57	员工_732	30	F	HR	2007-01-27	1974-06-13	上海市 随机街道3号	12966
13	员工_889	54	F	Sales	2000-11-09	1963-11-06	上海市 随机街道92号	20899
43	员工_335	48	F	Engineering	2008-11-30	1968-11-22	北京市 随机街道100号	31941
20	员工_546	47	M	Marketing	2006-05-30	1968-10-22	北京市 随机街道7号	18850
76	员工_705	43	M	HR	2003-12-28	1980-08-06	北京市 随机街道44号	40049
45	员工_959	39	F	HR	2005-12-21	1964-12-20	北京市 随机街道80号	23599
8	员工_402	57	F	Engineering	2006-02-04	1978-12-13	广州市 随机街道42号	19165
35	员工_88	35	F	Marketing	2005-11-21	1991-11-23	北京市 随机街道26号	29714
11	员工_475	25	F	Marketing	2003-07-21	1963-11-06	深圳市 随机街道9号	31657
36	员工_625	31	F	Marketing	2001-03-04	1983-03-14	深圳市 随机街道52号	24445
10	员工_268	37	F	Engineering	2003-12-07	1985-09-01	上海市 随机街道58号	19789
31	员工_569	49	M	Engineering	2005-09-21	1990-12-27	广州市 随机街道35号	11624
22	员工_116	50	F	Engineering	2007-04-17	1986-10-24	广州市 随机街道22号	22828
77	员工_40	50	M	HR	2007-08-31	1983-04-03	北京市 随机街道80号	3562
17	员工_213	46	M	Engineering	2007-03-23	1973-07-09	广州市 随机街道20号	29570
32	员工_6	53	F	Marketing	2001-09-25	1976-07-12	北京市 随机街道46号	7606
41	员工_825	22	M	Marketing	2000-10-21	1988-04-16	上海市 随机街道36号	31637
80	员工_695	59	F	Engineering	2006-08-14	1969-05-15	广州市 随机街道73号	48463
78	员工_188	45	F	Engineering	2001-03-02	1973-09-17	北京市 随机街道44号	13700
26	员工_347	33	F	HR	2006-08-03	1984-01-17	上海市 随机街道90号	9460
74	员工_330	33	M	HR	2003-12-24	1960-10-18	北京市 随机街道45号	6371
67	员工_520	54	M	Marketing	2002-02-11	1996-02-25	广州市 随机街道67号	44618
81	员工_673	47	F	HR	2008-03-20	1968-01-02	北京市 随机街道26号	22858
89	员工_829	19	F	Marketing	2001-11-05	1968-07-13	上海市 随机街道10号	31532
18	员工_672	35	M	Marketing	2003-06-17	1967-11-14	广州市 随机街道43号	26319
51	员工_919	27	F	Marketing	2000-03-18	1970-02-15	深圳市 随机街道56号	26677
65	员工_593	20	F	Marketing	2002-12-02	1989-09-22	广州市 随机街道77号	29403
40	员工_757	22	F	Engineering	2003-12-31	1962-08-10	上海市 随机街道31号	28932
16	员工_329	51	F	Marketing	2009-04-15	1986-03-14	上海市 随机街道56号	20753
46	员工_579	23	M	HR	2007-12-09	1974-10-02	北京市 随机街道2号	21267
49	员工_656	40	M	Engineering	2006-01-03	1996-06-25	深圳市 随机街道97号	44748
90	员工_597	59	M	Marketing	2005-01-16	1971-03-10	上海市 随机街道8号	21648
44	员工_509	43	F	Engineering	2005-02-16	1994-05-01	上海市 随机街道19号	11933
37	员工_867	51	M	Marketing	2003-04-25	1960-03-25	上海市 随机街道50号	24684
58	员工_229	53	F	Marketing	2007-05-16	2000-01-15	广州市 随机街道44号	16385
93	员工_542	25	M	HR	2004-07-06	1991-10-25	北京市 随机街道53号	11058
30	员工_433	22	M	Marketing	2005-08-28	1985-12-17	上海市 随机街道34号	30902
92	员工_36	51	M	HR	2002-03-13	1976-07-06	深圳市 随机街道33号	9660
73	员工_495	34	M	Marketing	2007-10-26	1972-12-31	上海市 随机街道29号	44047
82	员工_571	38	F	Engineering	2006-03-05	1961-11-17	广州市 随机街道32号	40112
71	员工_293	21	M	Engineering	2009-08-13	1961-03-15	北京市 随机街道6号	41599
97	员工_237	19	F	Marketing	2000-02-21	1967-05-23	北京市 随机街道2号	40402
88	员工_422	25	F	Marketing	2009-09-01	1999-03-23	上海市 随机街道72号	49217
96	员工_185	41	F	Marketing	2003-05-02	1991-01-11	广州市 随机街道37号	4321
24	员工_616	35	M	Marketing	2008-07-08	1987-10-30	深圳市 随机街道16号	23724
68	员工_217	29	F	Engineering	2001-03-24	1969-09-09	深圳市 随机街道36号	4392
84	员工_700	21	M	Marketing	2009-06-26	1966-08-11	北京市 随机街道53号	33951
63	员工_383	43	M	Engineering	2005-10-05	1969-11-15	广州市 随机街道77号	24202
42	员工_349	40	F	Marketing	2000-12-04	1977-01-04	上海市 随机街道32号	27774
25	员工_608	52	M	Engineering	2005-10-08	1974-01-05	广州市 随机街道1号	46880
94	员工_789	41	F	Marketing	2005-10-14	1985-05-15	上海市 随机街道53号	37576
86	员工_104	49	F	Engineering	2007-06-26	1965-07-28	上海市 随机街道22号	16293
87	员工_238	23	F	HR	2002-11-13	1997-02-26	深圳市 随机街道92号	48202
47	员工_61	44	F	Engineering	2004-11-19	2000-02-02	上海市 随机街道64号	47066
61	员工_62	55	F	HR	2004-02-09	1977-03-12	广州市 随机街道46号	6216
100	员工_936	52	M	HR	2008-08-27	1975-07-24	广州市 随机街道73号	14340
83	员工_135	50	F	Engineering	2006-07-08	1983-09-05	北京市 随机街道38号	28560
38	员工_190	21	M	HR	2003-05-25	1993-02-12	广州市 随机街道67号	31208
59	员工_59	27	F	Engineering	2007-03-30	1999-08-20	上海市 随机街道26号	8724
48	员工_510	52	F	HR	2005-04-08	1961-01-04	广州市 随机街道41号	7057
98	员工_30	27	F	Engineering	2008-04-23	2000-07-28	上海市 随机街道82号	3810
99	员工_999	21	M	Sales	2002-12-31	1969-12-27	广州市 随机街道50号	19614
54	员工_661	34	F	Sales	2003-08-06	1977-04-15	广州市 随机街道68号	15017
66	员工_677	32	F	Marketing	2003-02-11	1977-10-16	上海市 随机街道31号	11243
52	员工_112	24	M	Engineering	2003-06-03	1977-04-19	北京市 随机街道97号	35461
85	员工_949	26	M	Engineering	2006-05-02	1975-07-04	广州市 随机街道97号	36837
64	员工_339	25	F	Engineering	2005-09-23	1967-07-09	北京市 随机街道96号	47709
69	员工_90	51	M	Engineering	2006-06-27	1964-02-29	上海市 随机街道72号	40519
91	员工_641	19	M	Engineering	2000-08-24	1996-05-28	上海市 随机街道62号	45614
39	员工_75	50	M	Marketing	2001-11-01	1969-05-14	广州市 随机街道78号	45181
95	员工_997	43	F	HR	2000-03-07	1972-11-23	北京市 随机街道2号	33233
60	员工_550	58	M	Engineering	2005-01-09	1989-07-11	上海市 随机街道53号	6219
72	员工_521	44	F	HR	2007-05-06	1996-06-12	北京市 随机街道46号	35229
79	员工_411	28	F	HR	2008-08-06	1988-05-06	上海市 随机街道20号	27661
\.


--
-- Name: employees7_id_seq; Type: SEQUENCE SET; Schema: public; Owner: gpadmin
--

SELECT pg_catalog.setval('public.employees7_id_seq', 100, true);


--
-- Name: employees7_pkey; Type: CONSTRAINT; Schema: public; Owner: gpadmin; Tablespace: 
--

ALTER TABLE ONLY public.employees7
    ADD CONSTRAINT employees7_pkey PRIMARY KEY (id);


--
-- Greenplum Database database dump complete
--


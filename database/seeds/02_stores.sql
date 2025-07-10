-- Made in World Database Seeds: stores
-- Generated on: Wed Jul  9 21:26:15 CEST 2025
-- Source: Current database state from admin panel uploads

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.18 (Homebrew)
-- Dumped by pg_dump version 14.18 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.stores VALUES (3, 'Test Store', 'Test City', 'Test Address', 45.00000000, 9.00000000, '无人商店', false, '2025-07-08 18:29:54.7189+02', '2025-07-08 18:29:54.7189+02', NULL);
INSERT INTO public.stores VALUES (4, 'Active Test Store', 'Active Test City', 'Active Test Address', 45.00000000, 9.00000000, '无人商店', false, '2025-07-08 18:35:44.326783+02', '2025-07-08 18:38:45.649361+02', NULL);
INSERT INTO public.stores VALUES (5, 'Active Test Store', 'Active Test City', 'Active Test Address', 45.00000000, 9.00000000, '无人商店', false, '2025-07-08 18:36:32.895957+02', '2025-07-08 18:38:47.398815+02', NULL);
INSERT INTO public.stores VALUES (6, 'Active Test Store', 'Active Test City', 'Active Test Address', 45.00000000, 9.00000000, '无人商店', false, '2025-07-08 18:36:53.161647+02', '2025-07-08 18:38:49.03759+02', NULL);
INSERT INTO public.stores VALUES (8, 'Test Store', 'Test City', 'Test Address', 45.00000000, 9.00000000, '无人门店', false, '2025-07-08 18:43:53.623591+02', '2025-07-08 18:46:47.801169+02', NULL);
INSERT INTO public.stores VALUES (9, 'Test 无人仓店', 'Test City', 'Test Address', 45.00000000, 9.00000000, '无人仓店', false, '2025-07-08 18:45:35.776306+02', '2025-07-08 18:46:49.3855+02', NULL);
INSERT INTO public.stores VALUES (7, 'MANOR Lugano', 'Lugano', 'Salita M. e A. Chiattone 10, 6900 Lugano', 46.00516436, 8.95039408, '无人门店', true, '2025-07-08 18:40:36.148881+02', '2025-07-08 18:49:46.196806+02', '/uploads/stores/store_7_1751993386_MANORLugano.png');
INSERT INTO public.stores VALUES (10, 'Molino Nuovo', 'Lugano', 'Via Monte Boglia 5, 6900 Lugano', 46.01863606, 8.95863070, '无人门店', true, '2025-07-08 18:51:26.163521+02', '2025-07-08 18:52:09.61561+02', '/uploads/stores/store_10_1751993529_MolinoNuovo.jpg');
INSERT INTO public.stores VALUES (11, 'Viganello', 'Lugano', 'Via Molinazzo 1, 6962 Lugano', 46.01021036, 8.96450061, '无人仓店', true, '2025-07-08 18:52:55.501073+02', '2025-07-08 18:53:41.647376+02', '/uploads/stores/store_11_1751993621_Viganello.png');
INSERT INTO public.stores VALUES (12, 'Pregassona', 'Lugano', 'Viale Cassone 3, 6963 Lugano', 46.02053951, 8.96826120, '无人仓店', true, '2025-07-08 18:54:19.447648+02', '2025-07-08 18:54:58.924243+02', '/uploads/stores/store_12_1751993698_Pregassona.png');
INSERT INTO public.stores VALUES (13, 'Chiodenda', 'Agno', 'Via Chiodenda 7, 6982 Agno', 45.99895056, 8.90354473, '展销商城', true, '2025-07-08 18:56:05.750224+02', '2025-07-08 18:57:20.283284+02', '/uploads/stores/store_13_1751993840_Chiodenda.png');
INSERT INTO public.stores VALUES (14, 'Ceresio', 'Lugano', 'Via Ceresio 40, 6963 Lugano', 46.02149595, 8.96643840, '展销商城', true, '2025-07-08 18:58:07.224021+02', '2025-07-08 18:59:38.743408+02', '/uploads/stores/store_14_1751993978_Ceresio.png');
INSERT INTO public.stores VALUES (15, 'Porta di Roma', 'Roma', 'Via Alberto Lionello, 221, 00139 Roma RM, Italy', 41.97236997, 12.53906033, '展销商店', true, '2025-07-08 19:00:21.637715+02', '2025-07-08 19:03:19.316415+02', '/uploads/stores/store_15_1751994158_PortadiRoma.png');
INSERT INTO public.stores VALUES (16, 'ROMAEST', 'Roma', 'V. Collatina, Km 12.800, 00132 Roma RM, Italy', 41.91390471, 12.66100012, '展销商店', true, '2025-07-08 19:01:38.770602+02', '2025-07-08 19:03:24.151277+02', '/uploads/stores/store_16_1751994161_Romaest.png');


--
-- Name: stores_store_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.stores_store_id_seq', 16, true);


--
-- PostgreSQL database dump complete
--


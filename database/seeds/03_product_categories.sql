-- Made in World Database Seeds: product_categories
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
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.product_categories VALUES (5, 'Chanteclair', 'All', '2025-07-08 19:12:20.980621+02', '2025-07-08 19:15:57.555+02', '{RetailStore}', NULL, 1, false);
INSERT INTO public.product_categories VALUES (6, 'Chanteclair', 'All', '2025-07-08 19:16:03.439998+02', '2025-07-08 19:16:03.439998+02', '{RetailStore}', NULL, 1, true);
INSERT INTO public.product_categories VALUES (7, 'MAXI', 'All', '2025-07-09 18:42:07.106632+02', '2025-07-09 18:42:07.106632+02', '{RetailStore}', NULL, 2, true);
INSERT INTO public.product_categories VALUES (8, 'Chanteclair', 'All', '2025-07-09 18:44:16.714573+02', '2025-07-09 18:44:33.300232+02', '{UnmannedStore}', 7, 1, true);
INSERT INTO public.product_categories VALUES (9, 'Chanteclair', 'All', '2025-07-09 18:45:31.083421+02', '2025-07-09 18:45:31.083421+02', '{UnmannedStore}', 10, 1, true);
INSERT INTO public.product_categories VALUES (10, 'Chanteclair', 'All', '2025-07-09 18:49:41.216251+02', '2025-07-09 18:49:41.216251+02', '{UnmannedStore}', 11, 1, true);
INSERT INTO public.product_categories VALUES (11, 'Chanteclair', 'All', '2025-07-09 18:50:29.748183+02', '2025-07-09 18:50:29.748183+02', '{UnmannedStore}', 12, 1, true);
INSERT INTO public.product_categories VALUES (1, '展销商品', 'All', '2025-07-08 16:57:21.598729+02', '2025-07-09 18:51:53.391183+02', '{ExhibitionSales}', NULL, 0, false);
INSERT INTO public.product_categories VALUES (3, '特色产品', 'All', '2025-07-08 16:57:21.598729+02', '2025-07-09 18:51:55.503144+02', '{ExhibitionSales,GroupBuying}', NULL, 0, false);
INSERT INTO public.product_categories VALUES (12, 'MAXI', 'All', '2025-07-09 18:52:14.056733+02', '2025-07-09 18:52:14.056733+02', '{ExhibitionSales}', 13, 1, true);
INSERT INTO public.product_categories VALUES (13, 'MAXI', 'All', '2025-07-09 18:53:03.429152+02', '2025-07-09 18:53:03.429152+02', '{ExhibitionSales}', 14, 1, true);
INSERT INTO public.product_categories VALUES (14, 'MAXI', 'All', '2025-07-09 18:53:41.433037+02', '2025-07-09 18:53:41.433037+02', '{ExhibitionSales}', 15, 1, true);
INSERT INTO public.product_categories VALUES (15, 'MAXI', 'All', '2025-07-09 18:55:11.27344+02', '2025-07-09 18:55:11.27344+02', '{ExhibitionSales}', 16, 1, true);
INSERT INTO public.product_categories VALUES (2, '团购商品', 'All', '2025-07-08 16:57:21.598729+02', '2025-07-09 18:59:52.990595+02', '{GroupBuying}', NULL, 0, false);
INSERT INTO public.product_categories VALUES (4, '限时优惠', 'All', '2025-07-08 16:57:21.598729+02', '2025-07-09 18:59:54.759784+02', '{GroupBuying}', NULL, 0, false);
INSERT INTO public.product_categories VALUES (16, 'LEVISSIMA', 'All', '2025-07-09 19:02:08.043811+02', '2025-07-09 19:02:08.043811+02', '{GroupBuying}', NULL, 1, true);


--
-- Name: product_categories_category_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.product_categories_category_id_seq', 16, true);


--
-- PostgreSQL database dump complete
--


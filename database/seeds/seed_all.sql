-- Made in World Database Seeds - Complete Dataset
-- Generated on: Wed Jul  9 21:26:16 CEST 2025
-- Source: Current database state from admin panel uploads
--
-- This file contains all seed data in correct dependency order
-- Usage: psql -h host -U user -d dbname -f seed_all.sql

-- Disable triggers during import for better performance
SET session_replication_role = replica;


-- =============================================================================
-- 01_manufacturers.sql
-- =============================================================================

-- Made in World Database Seeds: manufacturers
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
-- Data for Name: manufacturers; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.manufacturers VALUES (1, 'Coca-Cola Company', 'John Smith', 'contact@coca-cola.com', 'Atlanta, GA, USA', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (2, 'Barilla Group', 'Marco Rossi', 'contact@barilla.com', 'Parma, Italy', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (3, 'Alpine Springs', 'Hans Mueller', 'contact@alpinesprings.ch', 'Swiss Alps, Switzerland', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (4, 'Lindt & Sprüngli', 'Pierre Dubois', 'contact@lindt.com', 'Kilchberg, Switzerland', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (5, 'Swiss Dairy Co.', 'Anna Weber', 'contact@swissdairy.ch', 'Bern, Switzerland', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (6, 'Mountain Honey', 'Klaus Fischer', 'contact@mountainhoney.ch', 'Graubünden, Switzerland', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');
INSERT INTO public.manufacturers VALUES (7, 'Swiss Timepieces', 'Jean-Claude Biver', 'contact@swisstimepieces.ch', 'Geneva, Switzerland', '2025-07-08 17:31:06.538749+02', '2025-07-08 17:31:06.538749+02');


--
-- Name: manufacturers_manufacturer_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.manufacturers_manufacturer_id_seq', 7, true);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 02_stores.sql
-- =============================================================================

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


-- =============================================================================
-- 03_product_categories.sql
-- =============================================================================

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


-- =============================================================================
-- 04_subcategories.sql
-- =============================================================================

-- Made in World Database Seeds: subcategories
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
-- Data for Name: subcategories; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.subcategories VALUES (22, 1, '地方特产', 'https://via.placeholder.com/150/FFF5F5/D92525?text=地方特产', 1, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (23, 1, '手工艺品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=手工艺品', 2, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (24, 1, '文化用品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=文化用品', 3, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (25, 2, '批发商品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=批发商品', 1, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (26, 2, '团购套餐', 'https://via.placeholder.com/150/FFF5F5/D92525?text=团购套餐', 2, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (27, 2, '企业采购', 'https://via.placeholder.com/150/FFF5F5/D92525?text=企业采购', 3, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (28, 3, '季节限定', 'https://via.placeholder.com/150/FFF5F5/D92525?text=季节限定', 1, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (29, 3, '新品推荐', 'https://via.placeholder.com/150/FFF5F5/D92525?text=新品推荐', 2, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (30, 4, '秒杀商品', 'https://via.placeholder.com/150/FFF5F5/D92525?text=秒杀商品', 1, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (31, 4, '拼团优惠', 'https://via.placeholder.com/150/FFF5F5/D92525?text=拼团优惠', 2, true, '2025-07-08 16:57:21.599558+02', '2025-07-08 16:57:21.599558+02');
INSERT INTO public.subcategories VALUES (32, 6, 'Sgrassatori', '/uploads/subcategories/subcategory_32_1751995093_Chante-Clair-sgrassatore-universale-625-ml-profumi-vari.jpg', 1, true, '2025-07-08 19:18:13.85724+02', '2025-07-08 19:18:13.86369+02');
INSERT INTO public.subcategories VALUES (33, 6, 'Bagno & Anticalcare', '/uploads/subcategories/subcategory_33_1752079287_71bUuPB9x9L._AC_SL1466_.jpg', 2, true, '2025-07-09 18:41:27.872813+02', '2025-07-09 18:41:27.883058+02');
INSERT INTO public.subcategories VALUES (34, 7, 'Carta Igienica', '/uploads/subcategories/subcategory_34_1752079430_104762-001_01__55387.jpeg', 1, true, '2025-07-09 18:43:50.719809+02', '2025-07-09 18:43:50.72783+02');
INSERT INTO public.subcategories VALUES (35, 8, 'Detersivi per Lavatrice', '/uploads/subcategories/subcategory_35_1752079521_81LsdSqTGkL._AC_SL1500_.jpg', 1, true, '2025-07-09 18:45:21.404347+02', '2025-07-09 18:45:21.414594+02');
INSERT INTO public.subcategories VALUES (36, 9, 'Ammorbidenti', '/uploads/subcategories/subcategory_36_1752079773_Ammorbidenti.jpeg', 1, true, '2025-07-09 18:49:33.711576+02', '2025-07-09 18:49:33.719272+02');
INSERT INTO public.subcategories VALUES (37, 10, 'Profuma Bucato', '/uploads/subcategories/subcategory_37_1752079823_i-concentrati-chanteclair-profuma-biancheria-jpg.jpeg', 1, true, '2025-07-09 18:50:23.79306+02', '2025-07-09 18:50:23.800623+02');
INSERT INTO public.subcategories VALUES (38, 11, 'Bucato a Mano', '/uploads/subcategories/subcategory_38_1752079901_Detersivi-per-lavatrice-Chanteclair.png', 1, true, '2025-07-09 18:51:41.201378+02', '2025-07-09 18:51:41.209191+02');
INSERT INTO public.subcategories VALUES (39, 12, 'Asciugatutto', '/uploads/subcategories/subcategory_39_1752079978_104769-001_01__89610.jpeg', 1, true, '2025-07-09 18:52:58.639605+02', '2025-07-09 18:52:58.645282+02');
INSERT INTO public.subcategories VALUES (40, 13, 'Bobine', '/uploads/subcategories/subcategory_40_1752080016_Bobine.png', 1, true, '2025-07-09 18:53:36.095623+02', '2025-07-09 18:53:36.102867+02');
INSERT INTO public.subcategories VALUES (41, 14, 'Tovaglioli', '/uploads/subcategories/subcategory_41_1752080105_104765-001_01__34305.jpeg', 1, true, '2025-07-09 18:55:05.094194+02', '2025-07-09 18:55:05.101572+02');
INSERT INTO public.subcategories VALUES (42, 15, 'Fazzoletti & Veline', '/uploads/subcategories/subcategory_42_1752080375_fazzoletti.jpeg', 1, true, '2025-07-09 18:59:35.655555+02', '2025-07-09 18:59:35.659348+02');
INSERT INTO public.subcategories VALUES (43, 16, 'LE NATURALI', '/uploads/subcategories/subcategory_43_1752080806_Levissima_acqua_naturale_0.jpeg', 1, true, '2025-07-09 19:06:46.62509+02', '2025-07-09 19:06:46.632194+02');


--
-- Name: subcategories_subcategory_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.subcategories_subcategory_id_seq', 43, true);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 05_products.sql
-- =============================================================================

-- Made in World Database Seeds: products
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
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.products VALUES (18, 'm00x00c00026', 'MAXI la Supercarta * 400 Tovaglioli Monovelo Compatto * 33 x 33', '', 'MAXI la Supercarta * 400 Tovaglioli Monovelo Compatto * 33 x 33', 1, '展销商店', 15, 3.99, 5.99, 0, 2, 1.29, true, false, true, '2025-07-09 20:44:28.295047+02', '2025-07-09 20:45:33.719325+02', 'cfb080c8-8b8e-455c-98ce-f1a49bdf63c9', 'ExhibitionSales');
INSERT INTO public.products VALUES (19, 'm00x00c00029', 'MAXI la Supercarta * Fazzoletti 3 Veli * 9 Fazzoletti per Pacchetto * 10 Pacchetti Morbidissimi', '', 'MAXI la Supercarta * Fazzoletti 3 Veli * 9 Fazzoletti per Pacchetto * 10 Pacchetti Morbidissimi', 1, '展销商店', 16, 2.19, 4.99, 0, 1, 0.99, true, true, true, '2025-07-09 20:46:15.090499+02', '2025-07-09 20:46:15.090499+02', '451149c0-acaf-4646-85ea-7665c6dcf5b6', 'ExhibitionSales');
INSERT INTO public.products VALUES (20, 'l00v00s00001', 'LEVISSIMA Naturale * 100% R-PET * Bottiglia 6 x 50 cL', '', 'LEVISSIMA Naturale * 100% R-PET * Bottiglia 6 x 50 cL', 1, '展销商店', NULL, 2.59, 3.50, 0, 2, 2.20, true, false, true, '2025-07-09 20:46:59.320583+02', '2025-07-09 20:46:59.320583+02', '081042fa-9da4-4b26-abbb-ff6a23240593', 'GroupBuying');
INSERT INTO public.products VALUES (9, 'c00t00c00001', 'Sgrassatore Universale Marsiglia', '', 'Sgrassatore Universale Marsiglia', 1, '展销商店', NULL, 2.99, 4.99, 0, 1, 1.59, true, false, true, '2025-07-09 19:11:14.972846+02', '2025-07-09 19:19:35.435218+02', 'a51669fe-c415-4241-8c94-e5f1601e4328', 'RetailStore');
INSERT INTO public.products VALUES (10, 'c00t00c00009', 'Anticalcare Universale Antigoccia', '', 'Anticalcare Universale Antigoccia', 1, '展销商店', NULL, 4.99, 8.99, 0, 2, 2.59, true, false, true, '2025-07-09 19:54:25.959234+02', '2025-07-09 19:54:25.959234+02', 'fea1e3d0-e912-4fd1-8037-999c64267789', 'RetailStore');
INSERT INTO public.products VALUES (11, 'm00x00c00001', 'MAXI la Supercarta * Carta Igienica 4 Rotoli Giganti 2500 x 2 Veli * 2500 Strappi', '', 'MAXI la Supercarta * Carta Igienica 4 Rotoli Giganti 2500 x 2 Veli * 2500 Strappi', 1, '展销商店', NULL, 4.99, 6.59, 0, 1, 2.10, true, false, false, '2025-07-09 19:55:40.181219+02', '2025-07-09 19:55:40.181219+02', 'a38e6599-eaf4-4651-8ae6-f7f9d2ffca59', 'RetailStore');
INSERT INTO public.products VALUES (12, 'c00t00c00020', 'Detersivo per Lavatrice Pulito Profondo', '', 'Detersivo per Lavatrice Pulito Profondo', 1, '无人门店', 7, 2.99, 5.99, 95, 1, 1.99, true, true, true, '2025-07-09 19:56:42.051038+02', '2025-07-09 20:38:37.452009+02', 'dd53ac1b-6eff-4bab-a405-b0c1edc9aa4c', 'UnmannedStore');
INSERT INTO public.products VALUES (13, 'c00t00c00026', 'Ammorbidenti i Concentrati Muschio Bianco', '', 'Ammorbidenti i Concentrati Muschio Bianco', 1, '无人门店', 10, 2.99, 5.99, 57, 1, 1.50, true, true, true, '2025-07-09 19:57:49.623424+02', '2025-07-09 20:38:46.28264+02', '79c41e72-f9a3-4c54-a877-27cf9d43993f', 'UnmannedStore');
INSERT INTO public.products VALUES (14, 'c00t00c00034', 'Profuma Biancheria i Concentrati Muschio Bianco', '', 'Profuma Biancheria i Concentrati Muschio Bianco', 1, '无人仓店', 11, 4.99, 8.59, 39, 2, 2.99, true, true, true, '2025-07-09 20:39:34.240335+02', '2025-07-09 20:39:34.240335+02', 'abfc9784-ff5f-46fa-97e9-f4e8e3330409', 'UnmannedStore');
INSERT INTO public.products VALUES (15, 'c00t00c00045', 'Detersivo Capi Sportivi e Fibre Sintetiche', '', 'Detersivo Capi Sportivi e Fibre Sintetiche', 1, '无人仓店', 12, 3.99, 5.99, 28, 2, 1.29, true, false, true, '2025-07-09 20:40:44.277179+02', '2025-07-09 20:40:44.277179+02', '2e354aec-9dbf-45ea-8fb3-864bc97dadba', 'UnmannedStore');
INSERT INTO public.products VALUES (16, 'm00x00c00013', 'MAXI la Supercarta * Asciugatutto 1 Rotolo Decorato x 2 Veli * 135 Strappi', '', 'MAXI la Supercarta * Asciugatutto 1 Rotolo Decorato x 2 Veli * 135 Strappi', 1, '展销商城', 13, 3.99, 5.99, 0, 3, 1.99, true, true, false, '2025-07-09 20:43:00.274598+02', '2025-07-09 20:43:00.274598+02', '52da3800-52ae-4df7-8715-e1eec32f5f74', 'ExhibitionSales');
INSERT INTO public.products VALUES (17, 'm00x00c00019', 'MAXI la Supercarta * BOBINOTTO 1 Rotolo Super Compatto x 2 Veli ', '', 'MAXI la Supercarta * BOBINOTTO 1 Rotolo Super Compatto x 2 Veli', 1, '展销商城', 14, 2.99, 4.99, 0, 3, 1.99, true, true, true, '2025-07-09 20:43:37.548439+02', '2025-07-09 20:43:37.548439+02', '1995d0ec-6273-4424-9070-21e2313f4d2f', 'ExhibitionSales');


--
-- Name: products_product_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.products_product_id_seq', 20, true);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 06_product_images.sql
-- =============================================================================

-- Made in World Database Seeds: product_images
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
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.product_images VALUES (8, 9, 'http://localhost:8080/uploads/products/9_1752081489182718000_9_1752081156210726000_chanteclair-sgrassatore-marsiglia-spray-600-ml.jpeg', 1, '2025-07-09 19:18:09.184598+02', true);
INSERT INTO public.product_images VALUES (10, 10, 'http://localhost:8080/uploads/products/10_1752083702437253000_8015194517892-070.png', 1, '2025-07-09 19:55:02.441086+02', true);
INSERT INTO public.product_images VALUES (11, 11, 'http://localhost:8080/uploads/products/11_1752083759334633000_Mock-up-Carta-Igienica-4-ROTOLI-GIGANTI-2500-strappi.png', 1, '2025-07-09 19:55:59.340405+02', true);
INSERT INTO public.product_images VALUES (12, 12, 'http://localhost:8080/uploads/products/12_1752083826322836000_Chanteclair-Lavatrice-Pulito-Profondo.png', 1, '2025-07-09 19:57:06.324603+02', true);
INSERT INTO public.product_images VALUES (13, 13, 'http://localhost:8080/uploads/products/13_1752083903460908000_chanteclair-i-concentrati-ammorbidente-muschio-bianco-1000-ml.png', 1, '2025-07-09 19:58:23.463871+02', true);
INSERT INTO public.product_images VALUES (14, 14, 'http://localhost:8080/uploads/products/14_1752086400583909000_61Cp-JR-8tL.jpg', 1, '2025-07-09 20:40:00.588273+02', true);
INSERT INTO public.product_images VALUES (15, 15, 'http://localhost:8080/uploads/products/15_1752086457469061000_c00t00c00045.jpeg', 1, '2025-07-09 20:40:57.471064+02', true);
INSERT INTO public.product_images VALUES (16, 16, 'http://localhost:8080/uploads/products/16_1752086583912446000_m00x00c00013.jpeg', 1, '2025-07-09 20:43:03.914091+02', true);
INSERT INTO public.product_images VALUES (17, 17, 'http://localhost:8080/uploads/products/17_1752086621175361000_m00x00c00019.jpeg', 1, '2025-07-09 20:43:41.176614+02', true);
INSERT INTO public.product_images VALUES (18, 18, 'http://localhost:8080/uploads/products/18_1752086671661083000_m00x00c00026.jpeg', 1, '2025-07-09 20:44:31.662497+02', true);
INSERT INTO public.product_images VALUES (19, 19, 'http://localhost:8080/uploads/products/19_1752086779569707000_m00x00c00029.jpeg', 1, '2025-07-09 20:46:19.571508+02', true);
INSERT INTO public.product_images VALUES (20, 20, 'http://localhost:8080/uploads/products/20_1752086822831018000_l00v00s00001.jpeg', 1, '2025-07-09 20:47:02.83196+02', true);


--
-- Name: product_images_image_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.product_images_image_id_seq', 20, true);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 07_product_category_mapping.sql
-- =============================================================================

-- Made in World Database Seeds: product_category_mapping
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
-- Data for Name: product_category_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.product_category_mapping VALUES (9, 6);
INSERT INTO public.product_category_mapping VALUES (10, 6);
INSERT INTO public.product_category_mapping VALUES (11, 7);
INSERT INTO public.product_category_mapping VALUES (12, 8);
INSERT INTO public.product_category_mapping VALUES (13, 9);
INSERT INTO public.product_category_mapping VALUES (14, 10);
INSERT INTO public.product_category_mapping VALUES (15, 11);
INSERT INTO public.product_category_mapping VALUES (16, 12);
INSERT INTO public.product_category_mapping VALUES (17, 13);
INSERT INTO public.product_category_mapping VALUES (18, 14);
INSERT INTO public.product_category_mapping VALUES (19, 15);
INSERT INTO public.product_category_mapping VALUES (20, 16);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 08_product_subcategory_mapping.sql
-- =============================================================================

-- Made in World Database Seeds: product_subcategory_mapping
-- Generated on: Wed Jul  9 21:26:16 CEST 2025
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
-- Data for Name: product_subcategory_mapping; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.product_subcategory_mapping VALUES (9, 32);
INSERT INTO public.product_subcategory_mapping VALUES (10, 33);
INSERT INTO public.product_subcategory_mapping VALUES (11, 34);
INSERT INTO public.product_subcategory_mapping VALUES (12, 35);
INSERT INTO public.product_subcategory_mapping VALUES (13, 36);
INSERT INTO public.product_subcategory_mapping VALUES (14, 37);
INSERT INTO public.product_subcategory_mapping VALUES (15, 38);
INSERT INTO public.product_subcategory_mapping VALUES (16, 39);
INSERT INTO public.product_subcategory_mapping VALUES (17, 40);
INSERT INTO public.product_subcategory_mapping VALUES (18, 41);
INSERT INTO public.product_subcategory_mapping VALUES (19, 42);
INSERT INTO public.product_subcategory_mapping VALUES (20, 43);


--
-- PostgreSQL database dump complete
--


-- =============================================================================
-- 09_inventory.sql
-- =============================================================================

-- Made in World Database Seeds: inventory
-- Generated on: Wed Jul  9 21:26:16 CEST 2025
-- Source: Current database state from admin panel uploads

-- Table inventory is empty

-- Re-enable triggers
SET session_replication_role = DEFAULT;

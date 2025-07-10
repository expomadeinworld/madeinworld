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


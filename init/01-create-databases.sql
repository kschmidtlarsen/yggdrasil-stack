-- ═══════════════════════════════════════════════════════════════════════════════
-- YGGDRASIL - Database Initialization
-- Creates databases for all platform services
-- ═══════════════════════════════════════════════════════════════════════════════

-- Kanban Board
CREATE DATABASE kanban_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Calify
CREATE DATABASE calify_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Grablist
CREATE DATABASE grablist_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- CoS (Chief of Staff)
CREATE DATABASE cos_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Night Tales
CREATE DATABASE nighttales_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Playwright Dashboard
CREATE DATABASE playwright_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Schmidt Larsen
CREATE DATABASE schmidtlarsen_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Sorring 3D
CREATE DATABASE sorring3d_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Sorring Udlejning
CREATE DATABASE sorring_udlejning_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- WODForge
CREATE DATABASE wodforge_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Mimir AI
CREATE DATABASE mimir_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Eir Backup Metadata
CREATE DATABASE eir_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Config (shared platform config: dep audits, doc baselines)
CREATE DATABASE config_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Yggdrasil Frontend (infrastructure ops platform)
CREATE DATABASE yggdrasil_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Stuffbase
CREATE DATABASE stuffbase_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Forseti
CREATE DATABASE forseti_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Legevenner
CREATE DATABASE legevenner_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Strider (real-time running coach)
CREATE DATABASE strider_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Huginn (channel-watch & auto-ingest platform)
CREATE DATABASE huginn_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Opportunity Scout (job-posting scraper & tracker)
CREATE DATABASE opportunity_scout_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Kvasir (BitNet local LLM inference service)
CREATE DATABASE kvasir_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

-- Warehouse read-plane (postgres_fdw federation over app DBs; card-ce569df9).
-- FDW servers/foreign-tables/views are set up separately: yggdrasil/warehouse/setup.sql
CREATE DATABASE warehouse_db
    WITH OWNER = urd
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TEMPLATE = template0;

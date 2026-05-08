-- ============================================================================
-- 20260101000001 — Baseline: extensions
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- pg_trgm: trigram-based fuzzy text search. Used by full-text search
-- features. Functions like similarity(), word_similarity(), and the
-- gin_trgm_* / gtrgm_* helpers come from this extension.

create extension if not exists pg_trgm with schema public;
create extension if not exists "uuid-ossp" with schema public;

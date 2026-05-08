-- ============================================================================
-- 20260101000002 — Baseline: helper functions
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- Internal helper functions used by triggers, RLS policies, and the JWT hook.

-- ─────────────────────────────────────────
-- touch_updated_at
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.touch_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

-- ─────────────────────────────────────────
-- tg_set_updated_at
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at := now();
  return new;
end;
$function$
;

-- ─────────────────────────────────────────
-- jwt_role
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.jwt_role()
 RETURNS text
 LANGUAGE sql
 STABLE
AS $function$
  SELECT COALESCE(auth.jwt() ->> 'app_role', '')
$function$
;

-- ─────────────────────────────────────────
-- jwt_tenant_id
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.jwt_tenant_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce((auth.jwt() ->> 'tenant_id')::uuid, '00000000-0000-0000-0000-000000000000'::uuid)
$function$
;

-- ─────────────────────────────────────────
-- jwt_pet_owner_id
-- ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.jwt_pet_owner_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE
AS $function$
  select case
    when (auth.jwt() ->> 'pet_owner_id') is not null
    then (auth.jwt() ->> 'pet_owner_id')::uuid
    else null
  end
$function$
;


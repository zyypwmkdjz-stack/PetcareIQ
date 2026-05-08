-- ============================================================================
-- 20260101000008 — Baseline: custom_access_token_hook
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- The JWT claims hook. Supabase auth calls this on every token issuance
-- to bake tenant_id + app_role claims into the access token. Without it,
-- the SPA cannot resolve which tenant the signed-in user belongs to.

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  claims jsonb;
  v_user_id uuid;
  v_tenant_id uuid;
  v_app_role text;
  v_staff_id uuid;
  v_pet_owner_id uuid;
BEGIN
  -- Defensive guards — never block token issuance for any reason
  IF event IS NULL THEN RETURN event; END IF;
  IF event->>'user_id' IS NULL THEN RETURN event; END IF;

  v_user_id := (event->>'user_id')::uuid;
  claims := COALESCE(event->'claims', '{}'::jsonb);

  BEGIN
    SELECT up.tenant_id, up.role::text
      INTO v_tenant_id, v_app_role
    FROM public.user_profiles up
    WHERE up.id = v_user_id;

    BEGIN
      SELECT sm.id INTO v_staff_id FROM public.staff_members sm WHERE sm.user_id = v_user_id LIMIT 1;
    EXCEPTION WHEN OTHERS THEN v_staff_id := NULL;
    END;
    BEGIN
      SELECT po.id INTO v_pet_owner_id FROM public.pet_owners po WHERE po.user_id = v_user_id LIMIT 1;
    EXCEPTION WHEN OTHERS THEN v_pet_owner_id := NULL;
    END;

    IF v_tenant_id    IS NOT NULL THEN claims := jsonb_set(claims, '{tenant_id}',    to_jsonb(v_tenant_id::text));    END IF;
    IF v_app_role     IS NOT NULL THEN claims := jsonb_set(claims, '{app_role}',     to_jsonb(v_app_role));           END IF;
    IF v_staff_id     IS NOT NULL THEN claims := jsonb_set(claims, '{staff_id}',     to_jsonb(v_staff_id::text));     END IF;
    IF v_pet_owner_id IS NOT NULL THEN claims := jsonb_set(claims, '{pet_owner_id}', to_jsonb(v_pet_owner_id::text)); END IF;

    event := jsonb_set(event, '{claims}', claims);
  EXCEPTION WHEN OTHERS THEN
    -- If anything fails, return event unchanged. Better to issue a token without
    -- our custom claims than to panic and break sign-in entirely.
    NULL;
  END;

  RETURN event;
END;
$function$
;

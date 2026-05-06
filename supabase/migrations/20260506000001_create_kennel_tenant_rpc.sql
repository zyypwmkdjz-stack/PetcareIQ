-- ============================================================================
-- 20260506000001 — create_kennel_tenant RPC
-- ----------------------------------------------------------------------------
-- Atomic tenant + user_profile creation for new sign-ups. Called by the SPA
-- after `supabase.auth.signUp()` resolves. SECURITY DEFINER so the two inserts
-- bypass RLS (the new user has no tenant scope yet — RLS would otherwise
-- block them).
--
-- After this RPC returns, the SPA must call `supa.auth.refreshSession()` so
-- the access token is reissued and the custom_access_token_hook bakes in the
-- new tenant_id + app_role claims.
-- ============================================================================

create or replace function public.create_kennel_tenant(
  p_name text,
  p_slug text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id   uuid;
  v_email     text;
  v_tenant_id uuid;
begin
  -- 1. Caller must be authenticated.
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated' using errcode = '42501';
  end if;

  -- 2. Block re-runs: caller must not already have a user_profiles row.
  --    This protects against double-signup and accidental re-call from the SPA.
  if exists (
    select 1 from public.user_profiles
    where id = v_user_id and deleted_at is null
  ) then
    raise exception 'User already belongs to a tenant'
      using errcode = '23505',
            hint    = 'Sign out and back in if you believe this is a mistake.';
  end if;

  -- 3. Validate inputs.
  if p_name is null or length(trim(p_name)) < 2 then
    raise exception 'Business name must be at least 2 characters'
      using errcode = '22023';
  end if;
  if length(trim(p_name)) > 120 then
    raise exception 'Business name must be 120 characters or fewer'
      using errcode = '22023';
  end if;
  if p_slug is null or p_slug !~ '^[a-z0-9][a-z0-9-]{1,48}[a-z0-9]$' then
    raise exception 'Slug must be 3-50 chars, lowercase a-z, 0-9, dashes only (no leading/trailing dash)'
      using errcode = '22023';
  end if;

  -- 4. Read the email off auth.users for the user_profiles convenience denorm.
  select email into v_email from auth.users where id = v_user_id;

  -- 5. Insert the tenant row. Production defaults: GB region, GBP currency,
  --    is_demo=false, setup_completed_at=null so the wizard fires on next render.
  --    Slug uniqueness is enforced by the existing unique index on tenants.slug —
  --    the SPA catches 23505 and retries with a suffix.
  insert into public.tenants (
    slug,
    name,
    region,
    currency_code,
    currency_symbol,
    currency_position,
    language,
    is_demo,
    setup_completed_at
  )
  values (
    trim(p_slug),
    trim(p_name),
    'GB',
    'GBP',
    '£',
    'before',
    'en-GB',
    false,
    null
  )
  returning id into v_tenant_id;

  -- 6. Create the user_profiles row linking the auth user to the new tenant
  --    as kennel_owner. The custom_access_token_hook reads from this table on
  --    next token refresh and adds tenant_id + app_role to JWT claims.
  insert into public.user_profiles (
    id,
    tenant_id,
    role,
    display_name,
    email
  )
  values (
    v_user_id,
    v_tenant_id,
    'kennel_owner',
    null,
    v_email
  );

  -- 7. Audit. Action: tenant.created. Note that entity_id is cast to text
  --    because migration 20260505000003 relaxed audit_log.entity_id to text.
  insert into public.audit_log (
    tenant_id,
    actor_user_id,
    action,
    entity_table,
    entity_id,
    details
  )
  values (
    v_tenant_id,
    v_user_id,
    'tenant.created',
    'tenants',
    v_tenant_id::text,
    jsonb_build_object(
      'slug', trim(p_slug),
      'name', trim(p_name),
      'source', 'create_kennel_tenant_rpc'
    )
  );

  return v_tenant_id;
end;
$$;

-- Lock down execution: only authenticated users can call this. Anon and public
-- are explicitly denied. The function is SECURITY DEFINER so it runs as the
-- function owner (postgres), which is what bypasses RLS for the inserts.
revoke execute on function public.create_kennel_tenant(text, text) from public, anon;
grant   execute on function public.create_kennel_tenant(text, text) to authenticated;

comment on function public.create_kennel_tenant(text, text) is
  'Atomic tenant + user_profile creation for new sign-ups. Caller must be authenticated and not yet have a profile. SECURITY DEFINER bypasses RLS for the two inserts. SPA must call supa.auth.refreshSession() after this returns so the JWT picks up the new tenant_id + app_role claims.';


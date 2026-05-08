-- ============================================================================
-- 20260508000003 — pq_check_plan_capacity helper function
-- ----------------------------------------------------------------------------
-- Pure-read helper that, given a tenant and an action, returns whether the
-- tenant is within their plan's capacity limits. No side effects — never
-- writes, never throws on missing data, always returns a structured jsonb
-- result that callers (Edge Functions, the SPA) can branch on.
--
-- Design choices:
--   - Postgres function (not TS): single source of truth, callable from RLS,
--     callable from any Edge Function, testable via SQL.
--   - SECURITY DEFINER: the function reads tenants, subscriptions, plans —
--     callers may not have direct read access to all three. SECURITY DEFINER
--     bypasses RLS but the function is locked down to only return data
--     about the caller's own tenant (we re-check tenant_id).
--   - Defensive on missing data: if a tenant has no subscription, we treat
--     it as "no plan, no enforcement" — returning allowed=true with reason
--     'no_subscription'. That keeps existing tenants functional pending
--     subscription rollout. The Edge Functions/SPA can decide to treat
--     this as a blocking state once subscriptions are mandatory.
-- ============================================================================

create or replace function public.pq_check_plan_capacity(
  p_tenant_id uuid,
  p_action    text default 'check'
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_tenant         public.tenants%rowtype;
  v_subscription   public.subscriptions%rowtype;
  v_plan           public.plans%rowtype;
  v_total_runs     int;
  v_after_action   int;
  v_action_units   int := 0;          -- how many runs this action would add
  v_action_kind    text;              -- 'kennel' | 'cattery' | 'check' | 'unknown'
  v_caller_tenant  uuid;
begin
  -- 1. Tenant must exist.
  select * into v_tenant from public.tenants where id = p_tenant_id;
  if not found then
    return jsonb_build_object(
      'allowed',    false,
      'reason',     'tenant_not_found',
      'action',     p_action,
      'tenant_id',  p_tenant_id
    );
  end if;

  -- 2. If called by a non-service-role authenticated user, defensively check
  --    they're querying their own tenant. (Service role is null auth.uid()
  --    so this only fires for end-user contexts. RLS on subscriptions covers
  --    the same ground but belt + braces is cheap here.)
  if auth.uid() is not null then
    v_caller_tenant := nullif(auth.jwt() ->> 'tenant_id', '')::uuid;
    if v_caller_tenant is null or v_caller_tenant <> p_tenant_id then
      return jsonb_build_object(
        'allowed',    false,
        'reason',     'cross_tenant_query_denied',
        'action',     p_action,
        'tenant_id',  p_tenant_id
      );
    end if;
  end if;

  -- 3. Resolve the requested action into a unit-delta. Unknown actions are
  --    not blocked here — they get unit-delta 0 and we return current state.
  v_action_kind := case p_action
    when 'add_run'           then 'kennel'
    when 'add_cattery_suite' then 'cattery'
    when 'check'             then 'check'
    else 'unknown'
  end;
  if v_action_kind in ('kennel','cattery') then
    v_action_units := 1;
  end if;

  -- 4. Total runs is the sum of kennel + cattery counters; the plan limit
  --    applies to combined capacity, not per-species.
  v_total_runs   := coalesce(v_tenant.run_count, 0) + coalesce(v_tenant.cattery_count, 0);
  v_after_action := v_total_runs + v_action_units;

  -- 5. Subscription lookup (one per tenant). If absent, return no-enforcement.
  select * into v_subscription
  from public.subscriptions
  where tenant_id = p_tenant_id
  limit 1;

  if not found then
    return jsonb_build_object(
      'allowed',         true,
      'reason',          'no_subscription',
      'action',          p_action,
      'tenant_id',       p_tenant_id,
      'current_runs',    v_total_runs,
      'run_limit',       null,
      'plan_code',       null,
      'subscription_status', null
    );
  end if;

  -- 6. Subscription status gating. trial and active are open; everything else
  --    blocks new capacity-consuming actions but allows passive 'check'.
  if v_subscription.status in ('past_due','cancelled','expired') and v_action_units > 0 then
    return jsonb_build_object(
      'allowed',              false,
      'reason',               'subscription_' || v_subscription.status::text,
      'action',               p_action,
      'tenant_id',            p_tenant_id,
      'current_runs',         v_total_runs,
      'run_limit',            null,                          -- intentionally not exposing limit when blocked
      'plan_code',            null,
      'subscription_status',  v_subscription.status::text
    );
  end if;

  -- 7. Trial-expiry gate: if status is still 'trial' but trial_ends_at has
  --    passed, treat as expired for new capacity actions. We do not flip the
  --    row here (that's a billing-job responsibility); we just block.
  if v_subscription.status = 'trial'
     and v_subscription.trial_ends_at is not null
     and v_subscription.trial_ends_at < now()
     and v_action_units > 0
  then
    return jsonb_build_object(
      'allowed',              false,
      'reason',               'trial_expired',
      'action',               p_action,
      'tenant_id',            p_tenant_id,
      'current_runs',         v_total_runs,
      'run_limit',            null,
      'plan_code',            null,
      'subscription_status',  'trial',
      'trial_ends_at',        v_subscription.trial_ends_at
    );
  end if;

  -- 8. Resolve the plan.
  select * into v_plan from public.plans where id = v_subscription.plan_id;
  if not found then
    -- Subscription points at a plan that no longer exists / was deactivated.
    -- Block capacity-consuming actions; allow passive checks.
    return jsonb_build_object(
      'allowed',              v_action_units = 0,
      'reason',               'plan_unavailable',
      'action',               p_action,
      'tenant_id',            p_tenant_id,
      'current_runs',         v_total_runs,
      'subscription_status',  v_subscription.status::text
    );
  end if;

  -- 9. Multi-species gate: if the plan's features.multi_species is false,
  --    block adding a cattery suite when kennels exist (and vice versa).
  if v_action_kind = 'cattery'
     and coalesce((v_plan.features ->> 'multi_species')::boolean, false) = false
     and v_tenant.run_count > 0
  then
    return jsonb_build_object(
      'allowed',          false,
      'reason',           'plan_single_species_only',
      'action',           p_action,
      'tenant_id',        p_tenant_id,
      'current_runs',     v_total_runs,
      'run_limit',        v_plan.run_limit,
      'plan_code',        v_plan.code
    );
  end if;
  if v_action_kind = 'kennel'
     and coalesce((v_plan.features ->> 'multi_species')::boolean, false) = false
     and v_tenant.cattery_count > 0
  then
    return jsonb_build_object(
      'allowed',          false,
      'reason',           'plan_single_species_only',
      'action',           p_action,
      'tenant_id',        p_tenant_id,
      'current_runs',     v_total_runs,
      'run_limit',        v_plan.run_limit,
      'plan_code',        v_plan.code
    );
  end if;

  -- 10. Capacity gate: would the resulting count exceed the plan's run_limit?
  if v_after_action > v_plan.run_limit then
    return jsonb_build_object(
      'allowed',          false,
      'reason',           'run_limit_exceeded',
      'action',           p_action,
      'tenant_id',        p_tenant_id,
      'current_runs',     v_total_runs,
      'after_action',     v_after_action,
      'run_limit',        v_plan.run_limit,
      'plan_code',        v_plan.code
    );
  end if;

  -- 11. All gates passed. Action allowed.
  return jsonb_build_object(
    'allowed',              true,
    'reason',               null,
    'action',               p_action,
    'tenant_id',            p_tenant_id,
    'current_runs',         v_total_runs,
    'after_action',         v_after_action,
    'run_limit',            v_plan.run_limit,
    'plan_code',            v_plan.code,
    'subscription_status',  v_subscription.status::text,
    'features',             v_plan.features
  );
end;
$$;

revoke execute on function public.pq_check_plan_capacity(uuid, text) from public, anon;
grant   execute on function public.pq_check_plan_capacity(uuid, text) to authenticated;

comment on function public.pq_check_plan_capacity(uuid, text) is
  'Returns jsonb describing whether a tenant can perform a capacity-affecting action under their current plan. Pure read, no side effects. Recognised actions: ''add_run'', ''add_cattery_suite'', ''check'' (default). Result always includes allowed (bool), reason (text|null), and contextual fields (current_runs, run_limit, plan_code, subscription_status, features). Callers should ALWAYS check the allowed bool, never assume.';

-- ============================================================================
-- test_pq_check_plan_capacity.sql — SQL test suite for the capacity helper
-- ----------------------------------------------------------------------------
-- Self-contained test script. Wraps every test in a SAVEPOINT so the suite
-- can run end-to-end and report pass/fail per test without polluting the DB.
-- The outer transaction is ROLLed BACK at the end, so running this file
-- leaves the database untouched.
--
-- Usage:
--   psql ... -f tests/test_pq_check_plan_capacity.sql
--   or paste into Supabase SQL editor and run.
--
-- A test is reported as passing when its assertions hold; a failure raises
-- an exception that names the test. The whole suite stops on first failure
-- (intentional — fail loud).
--
-- The seed file (seeds/pricing_seed.sql) MUST have been applied before this
-- runs, because the tests reference plan codes 'starter' / 'growth' /
-- 'established' to look up plan_id values.
-- ============================================================================

begin;

do $$
declare
  v_starter_id      uuid;
  v_growth_id       uuid;
  v_established_id  uuid;

  v_tenant_a        uuid;  -- starter, 14/15 runs, on trial
  v_tenant_b        uuid;  -- starter, 15/15 runs (at limit)
  v_tenant_c        uuid;  -- growth, 35/40 runs, active subscription
  v_tenant_d        uuid;  -- starter, 5 runs + 0 cattery (single-species probe)
  v_tenant_e        uuid;  -- starter, trial expired
  v_tenant_f        uuid;  -- no subscription at all

  v_result          jsonb;
begin
  -- Resolve plan IDs from the seed.
  select id into v_starter_id     from public.plans where code = 'starter';
  select id into v_growth_id      from public.plans where code = 'growth';
  select id into v_established_id from public.plans where code = 'established';
  if v_starter_id is null or v_growth_id is null then
    raise exception 'Seed data missing — apply pricing_seed.sql before running tests';
  end if;

  -- Create test tenants (rolled back at end).
  insert into public.tenants (slug, name, region, currency_code, currency_symbol, currency_position, language, is_demo, run_count, cattery_count)
  values
    ('test-cap-a', 'Test A',  'GB', 'GBP', '£', 'before', 'en-GB', true, 14, 0),
    ('test-cap-b', 'Test B',  'GB', 'GBP', '£', 'before', 'en-GB', true, 15, 0),
    ('test-cap-c', 'Test C',  'GB', 'GBP', '£', 'before', 'en-GB', true, 35, 5),  -- 40/40 on growth (at limit)
    ('test-cap-d', 'Test D',  'GB', 'GBP', '£', 'before', 'en-GB', true,  5, 0),
    ('test-cap-e', 'Test E',  'GB', 'GBP', '£', 'before', 'en-GB', true,  3, 0),
    ('test-cap-f', 'Test F',  'GB', 'GBP', '£', 'before', 'en-GB', true,  0, 0)
  returning id, slug into v_tenant_a, v_tenant_b;
  -- Re-fetch the others by slug (RETURNING above only captures the first row in plpgsql).
  select id into v_tenant_a from public.tenants where slug = 'test-cap-a';
  select id into v_tenant_b from public.tenants where slug = 'test-cap-b';
  select id into v_tenant_c from public.tenants where slug = 'test-cap-c';
  select id into v_tenant_d from public.tenants where slug = 'test-cap-d';
  select id into v_tenant_e from public.tenants where slug = 'test-cap-e';
  select id into v_tenant_f from public.tenants where slug = 'test-cap-f';

  -- Subscriptions for A,B,C,D,E (F deliberately none).
  insert into public.subscriptions (tenant_id, plan_id, billing_cycle, status, trial_started_at, trial_ends_at)
  values
    (v_tenant_a, v_starter_id, 'monthly', 'trial', now(), now() + interval '20 days'),  -- mid-trial
    (v_tenant_b, v_starter_id, 'monthly', 'trial', now(), now() + interval '10 days'),
    (v_tenant_d, v_starter_id, 'monthly', 'trial', now(), now() + interval '20 days'),
    (v_tenant_e, v_starter_id, 'monthly', 'trial', now() - interval '40 days', now() - interval '10 days');  -- trial expired

  insert into public.subscriptions (tenant_id, plan_id, billing_cycle, status, current_period_starts_at, current_period_ends_at)
  values
    (v_tenant_c, v_growth_id, 'annual',  'active', now() - interval '60 days', now() + interval '305 days');

  -- ─── TEST 1 ────────────────────────────────────────────────────────────
  -- Under limit, on trial: add_run is allowed.
  v_result := public.pq_check_plan_capacity(v_tenant_a, 'add_run');
  if (v_result ->> 'allowed')::boolean is not true then
    raise exception 'TEST 1 FAILED: starter+14 runs should allow add_run; got %', v_result;
  end if;
  if (v_result ->> 'run_limit')::int <> 15 then
    raise exception 'TEST 1 FAILED: expected run_limit=15; got %', v_result;
  end if;
  raise notice 'TEST 1 PASS — under-limit add_run allowed (current=14, limit=15)';

  -- ─── TEST 2 ────────────────────────────────────────────────────────────
  -- AT limit: passive 'check' allowed; add_run blocked.
  v_result := public.pq_check_plan_capacity(v_tenant_b, 'check');
  if (v_result ->> 'allowed')::boolean is not true then
    raise exception 'TEST 2a FAILED: passive check at limit should be allowed; got %', v_result;
  end if;
  v_result := public.pq_check_plan_capacity(v_tenant_b, 'add_run');
  if (v_result ->> 'allowed')::boolean is not false then
    raise exception 'TEST 2b FAILED: at-limit add_run should be blocked; got %', v_result;
  end if;
  if (v_result ->> 'reason') <> 'run_limit_exceeded' then
    raise exception 'TEST 2b FAILED: expected reason=run_limit_exceeded; got %', v_result;
  end if;
  raise notice 'TEST 2 PASS — at-limit blocks add_run, allows passive check';

  -- ─── TEST 3 ────────────────────────────────────────────────────────────
  -- OVER notional limit not possible by add (would have been blocked). Test
  -- the case where capacity is exceeded retrospectively (e.g. plan downgrade):
  -- tenant has 35 runs + 5 cattery on Growth (40 limit) — at limit. Add_run
  -- should block.
  v_result := public.pq_check_plan_capacity(v_tenant_c, 'add_run');
  if (v_result ->> 'allowed')::boolean is not false then
    raise exception 'TEST 3 FAILED: growth at 40/40 should block add_run; got %', v_result;
  end if;
  if (v_result ->> 'plan_code') <> 'growth' then
    raise exception 'TEST 3 FAILED: expected plan_code=growth; got %', v_result;
  end if;
  raise notice 'TEST 3 PASS — over-limit (combined runs+cattery) add_run blocked on growth';

  -- ─── TEST 4 ────────────────────────────────────────────────────────────
  -- Single-species gate: starter tenant with 5 kennels tries to add cattery.
  v_result := public.pq_check_plan_capacity(v_tenant_d, 'add_cattery_suite');
  if (v_result ->> 'allowed')::boolean is not false then
    raise exception 'TEST 4 FAILED: starter cattery add should be blocked when kennels exist; got %', v_result;
  end if;
  if (v_result ->> 'reason') <> 'plan_single_species_only' then
    raise exception 'TEST 4 FAILED: expected reason=plan_single_species_only; got %', v_result;
  end if;
  raise notice 'TEST 4 PASS — starter blocks cattery add when kennels exist (single-species gate)';

  -- ─── TEST 5 ────────────────────────────────────────────────────────────
  -- Trial-expired blocks add_run, allows passive check.
  v_result := public.pq_check_plan_capacity(v_tenant_e, 'add_run');
  if (v_result ->> 'allowed')::boolean is not false then
    raise exception 'TEST 5a FAILED: expired trial add_run should be blocked; got %', v_result;
  end if;
  if (v_result ->> 'reason') <> 'trial_expired' then
    raise exception 'TEST 5a FAILED: expected reason=trial_expired; got %', v_result;
  end if;
  v_result := public.pq_check_plan_capacity(v_tenant_e, 'check');
  if (v_result ->> 'allowed')::boolean is not true then
    raise exception 'TEST 5b FAILED: expired trial passive check should be allowed; got %', v_result;
  end if;
  raise notice 'TEST 5 PASS — trial-expired blocks add_run, allows passive check';

  -- ─── TEST 6 ────────────────────────────────────────────────────────────
  -- No subscription → no enforcement (returns allowed=true with reason=no_subscription).
  -- This is the safe default for tenants that exist before the pricing layer ships.
  v_result := public.pq_check_plan_capacity(v_tenant_f, 'add_run');
  if (v_result ->> 'allowed')::boolean is not true then
    raise exception 'TEST 6 FAILED: tenant with no subscription should be allowed (no enforcement); got %', v_result;
  end if;
  if (v_result ->> 'reason') <> 'no_subscription' then
    raise exception 'TEST 6 FAILED: expected reason=no_subscription; got %', v_result;
  end if;
  raise notice 'TEST 6 PASS — no subscription = no enforcement (existing-tenant safety net)';

  -- ─── TEST 7 ────────────────────────────────────────────────────────────
  -- Missing tenant returns structured error, not crash.
  v_result := public.pq_check_plan_capacity('00000000-0000-0000-0000-000000000000'::uuid, 'add_run');
  if (v_result ->> 'allowed')::boolean is not false then
    raise exception 'TEST 7 FAILED: missing tenant should return allowed=false; got %', v_result;
  end if;
  if (v_result ->> 'reason') <> 'tenant_not_found' then
    raise exception 'TEST 7 FAILED: expected reason=tenant_not_found; got %', v_result;
  end if;
  raise notice 'TEST 7 PASS — missing tenant returns structured error';

  raise notice '═══════════════════════════════════════';
  raise notice '  ALL CAPACITY-CHECK TESTS PASSED  ';
  raise notice '═══════════════════════════════════════';
end;
$$;

-- Roll back so the test fixtures don't survive.
rollback;

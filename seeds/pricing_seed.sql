-- ============================================================================
-- pricing_seed.sql — initial catalogue data
-- ----------------------------------------------------------------------------
-- Seeds the three plans, the standard add-on catalogue, and the pilot
-- discount. Idempotent: re-running this file overwrites the catalogue rows
-- by code (plans.code, addons.code, discounts.code) without disturbing
-- subscription rows that reference them.
--
-- Run via Supabase SQL editor or `psql` against the project. Not applied
-- automatically (this is a seed, not a migration).
--
-- All prices are placeholders pending external pricing recon. To change a
-- price, edit the value here and re-run the seed — production code reads
-- prices from the DB, never from constants.
-- ============================================================================

begin;

-- ───────────────────────────────────────────────────────────────────────
-- Plans
-- ----------------------------------------------------------------------
-- Feature-flag schema (kept consistent across all plans):
--   multi_species          : kennels AND cattery on same tenant
--   multi_site             : > 1 site permitted
--   staff_scheduling       : forward-planner + roster surfaces
--   customer_portal        : pet owner self-service portal
--   messaging              : in-app messaging to customers
--   daycare                : daycare/training booking flows
--   advanced_reporting     : reporting suite beyond core ops
--   api_access             : public API + webhooks
--   payments_integration   : Stripe-powered customer card payments
-- ───────────────────────────────────────────────────────────────────────

insert into public.plans
  (code, name, description, run_limit, monthly_price_pence, annual_price_pence, features, sort_order)
values
  (
    'starter',
    'Starter',
    'For small kennels just getting started. Up to 15 runs, single-species, single-site.',
    15,
    4900,    -- £49.00 / month
    49000,   -- £490.00 / year (~17% discount, two months free)
    jsonb_build_object(
      'multi_species',        false,
      'multi_site',           false,
      'staff_scheduling',     false,
      'customer_portal',      false,
      'messaging',            false,
      'daycare',              false,
      'advanced_reporting',   false,
      'api_access',           false,
      'payments_integration', false
    ),
    10
  ),
  (
    'growth',
    'Growth',
    'For growing operations. Up to 40 runs, kennels + cattery, staff scheduling, customer portal and messaging.',
    40,
    8900,    -- £89.00 / month
    89000,   -- £890.00 / year
    jsonb_build_object(
      'multi_species',        true,
      'multi_site',           false,
      'staff_scheduling',     true,
      'customer_portal',      true,
      'messaging',            true,
      'daycare',              false,
      'advanced_reporting',   false,
      'api_access',           false,
      'payments_integration', false
    ),
    20
  ),
  (
    'established',
    'Established',
    'For multi-site operations. 41+ runs, multi-site, daycare, advanced reporting, API access, payments integration.',
    1000,    -- effectively no run cap; the brief says "41+", we set a generous ceiling
    17900,   -- £179.00 / month
    179000,  -- £1,790.00 / year
    jsonb_build_object(
      'multi_species',        true,
      'multi_site',           true,
      'staff_scheduling',     true,
      'customer_portal',      true,
      'messaging',            true,
      'daycare',              true,
      'advanced_reporting',   true,
      'api_access',           true,
      'payments_integration', true
    ),
    30
  )
on conflict (code) do update set
  name                = excluded.name,
  description         = excluded.description,
  run_limit           = excluded.run_limit,
  monthly_price_pence = excluded.monthly_price_pence,
  annual_price_pence  = excluded.annual_price_pence,
  features            = excluded.features,
  sort_order          = excluded.sort_order,
  is_active           = true;

-- ───────────────────────────────────────────────────────────────────────
-- Add-ons
-- ───────────────────────────────────────────────────────────────────────

insert into public.addons
  (code, name, description, pricing_model, price_pence, unit_price_pence, unit_label, percent_rate)
values
  (
    'sms_bundle',
    'SMS messaging',
    'Send SMS reminders and updates to customers. Billed per message at passthrough Twilio cost plus margin.',
    'per_unit',
    null, 4, 'sms', null  -- 4p / SMS placeholder
  ),
  (
    'payments_fee',
    'Integrated payments',
    'Process customer card payments through the booking flow. Surcharge added on top of Stripe processing fees.',
    'percentage_passthrough',
    null, null, null, 1.500  -- 1.5% surcharge placeholder
  ),
  (
    'custom_domain',
    'Custom domain',
    'Use your own domain for the booking page (e.g. book.yourkennels.com).',
    'flat_monthly',
    1500, null, null, null  -- £15 / month
  ),
  (
    'extra_seat',
    'Extra staff user',
    'Additional staff user beyond your tier''s seat allowance.',
    'per_unit',
    null, 500, 'staff_seat', null  -- £5 / month / extra seat
  ),
  (
    'multi_site',
    'Additional site',
    'Operate a second (or further) physical site under the same account. Included for free on Established.',
    'per_unit',
    null, 2900, 'site', null  -- £29 / month / extra site for Starter+Growth
  )
on conflict (code) do update set
  name             = excluded.name,
  description      = excluded.description,
  pricing_model    = excluded.pricing_model,
  price_pence      = excluded.price_pence,
  unit_price_pence = excluded.unit_price_pence,
  unit_label       = excluded.unit_label,
  percent_rate     = excluded.percent_rate,
  is_active        = true;

-- ───────────────────────────────────────────────────────────────────────
-- Discounts — pilot programme
-- ───────────────────────────────────────────────────────────────────────

insert into public.discounts
  (code, name, description, percent_off, duration_months, valid_until, max_redemptions)
values
  (
    'PILOT_50_24',
    'Pilot programme — 50% off for 24 months',
    'Locked-in pilot pricing for the first cohort of customers. 50% discount for 24 months from subscription start.',
    50.00,
    24,
    null,    -- no end date on the coupon itself; we manage availability via is_active
    null     -- no redemption cap; flip is_active = false to close the cohort
  )
on conflict (code) do update set
  name              = excluded.name,
  description       = excluded.description,
  percent_off       = excluded.percent_off,
  duration_months   = excluded.duration_months,
  valid_until       = excluded.valid_until,
  max_redemptions   = excluded.max_redemptions,
  is_active         = true;

commit;

-- Quick sanity check (uncomment to verify after a seed run):
-- select code, run_limit, monthly_price_pence, annual_price_pence from public.plans     order by sort_order;
-- select code, pricing_model, price_pence, unit_price_pence, unit_label, percent_rate from public.addons;
-- select code, percent_off, duration_months, is_active from public.discounts;

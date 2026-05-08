-- ============================================================================
-- 20260508000002 — Create pricing schema (plans, addons, discounts,
--                  subscriptions, subscription_addons) + RLS policies
-- ----------------------------------------------------------------------------
-- Foundational schema for SaaS pricing. NO Stripe integration, NO UI, NO
-- signup wiring in this migration — those are downstream concerns. This
-- migration only establishes the data model + access controls.
--
-- Naming: pricing-layer tables are deliberately distinct from the SPA's
-- existing "billing" namespace, which refers to kennel→customer invoicing.
-- Plans/subscriptions/addons here are SaaS-tier concerns only.
--
-- Money: stored as integer pence (UK-first product, all GBP). A £49 monthly
-- price is stored as 4900. Cross-currency support is a future concern.
--
-- Plan-feature gating is implemented via a JSONB `features` blob on plans.
-- The SPA reads this blob to enable/disable feature surfaces. Documented
-- feature keys (with current tier defaults) are listed in the seed file.
-- ============================================================================

-- ───────────────────────────────────────────────────────────────────────
-- Enums
-- ───────────────────────────────────────────────────────────────────────

create type public.addon_pricing_model as enum (
  'flat_monthly',           -- one fixed monthly fee (e.g. custom domain)
  'per_unit',               -- billed per consumption unit (e.g. SMS)
  'percentage_passthrough'  -- % surcharge on a passthrough cost (e.g. payments)
);

create type public.billing_cycle as enum (
  'monthly',
  'annual'
);

create type public.subscription_status as enum (
  'trial',     -- in 30-day (or extended 45-day) trial; not billable yet
  'active',    -- paying customer, in good standing
  'past_due',  -- payment failed, grace window before downgrade
  'cancelled', -- tenant initiated cancellation; access continues until period end
  'expired'    -- trial elapsed without conversion, or subscription fully terminated
);

-- ───────────────────────────────────────────────────────────────────────
-- plans — the catalogue of subscription tiers
-- ───────────────────────────────────────────────────────────────────────

create table public.plans (
  id                  uuid primary key default gen_random_uuid(),
  code                text not null unique,            -- 'starter' | 'growth' | 'established'
  name                text not null,
  description         text,
  run_limit           int  not null check (run_limit > 0),
  monthly_price_pence int  not null check (monthly_price_pence >= 0),
  annual_price_pence  int  not null check (annual_price_pence  >= 0),
  features            jsonb not null default '{}'::jsonb,
  is_active           boolean not null default true,
  sort_order          int not null default 0,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table public.plans is
  'Subscription tier catalogue. Globally readable (catalog), service-role write only.';
comment on column public.plans.run_limit is
  'Maximum combined kennels + cattery suites allowed on this tier. Enforced by pq_check_plan_capacity.';
comment on column public.plans.features is
  'JSONB feature flags. Documented keys: multi_species, multi_site, staff_scheduling, customer_portal, messaging, daycare, api_access, advanced_reporting, payments_integration. See seed file for tier-by-tier values.';

create index idx_plans_active_sort on public.plans (is_active, sort_order)
  where is_active = true;

-- ───────────────────────────────────────────────────────────────────────
-- addons — orthogonal capabilities purchasable on top of any tier
-- ───────────────────────────────────────────────────────────────────────

create table public.addons (
  id                uuid primary key default gen_random_uuid(),
  code              text not null unique,    -- 'sms_bundle' | 'payments_fee' | 'custom_domain' | 'extra_seat' | 'multi_site'
  name              text not null,
  description       text,
  pricing_model     public.addon_pricing_model not null,

  -- Exactly one price-shaped column is populated, depending on pricing_model.
  price_pence       int,                     -- flat_monthly
  unit_price_pence  int,                     -- per_unit
  unit_label        text,                    -- per_unit human-readable (e.g. 'sms', 'staff_seat')
  percent_rate      numeric(6,3),            -- percentage_passthrough (e.g. 1.500 = 1.5%)

  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),

  constraint addon_pricing_model_consistency check (
    (pricing_model = 'flat_monthly' and price_pence is not null
       and unit_price_pence is null and percent_rate is null)
    or
    (pricing_model = 'per_unit' and unit_price_pence is not null and unit_label is not null
       and price_pence is null and percent_rate is null)
    or
    (pricing_model = 'percentage_passthrough' and percent_rate is not null
       and price_pence is null and unit_price_pence is null)
  )
);

comment on table public.addons is
  'Add-on catalogue. Orthogonal to plan tier — same add-ons can be attached to any tier. Globally readable, service-role write only.';

-- ───────────────────────────────────────────────────────────────────────
-- discounts — coupon codes (e.g. pilot 50%-off-for-24-months)
-- ───────────────────────────────────────────────────────────────────────

create table public.discounts (
  id                uuid primary key default gen_random_uuid(),
  code              text not null unique,             -- 'PILOT_50_24'
  name              text not null,
  description       text,
  percent_off       numeric(5,2) not null check (percent_off > 0 and percent_off <= 100),
  duration_months   int not null check (duration_months > 0),
  valid_from        timestamptz,                       -- nullable = always valid from inception
  valid_until       timestamptz,                       -- nullable = no end date
  max_redemptions   int check (max_redemptions is null or max_redemptions > 0),
  redemption_count  int not null default 0 check (redemption_count >= 0),
  is_active         boolean not null default true,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

comment on table public.discounts is
  'Coupon/discount catalogue. One discount may be applied to many subscriptions, but each subscription has at most one active discount at a time (subscriptions.applied_discount_id).';

-- ───────────────────────────────────────────────────────────────────────
-- subscriptions — one-per-tenant
-- ───────────────────────────────────────────────────────────────────────

create table public.subscriptions (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null unique references public.tenants(id) on delete cascade,
  plan_id                     uuid not null references public.plans(id),
  billing_cycle               public.billing_cycle not null default 'monthly',
  status                      public.subscription_status not null default 'trial',

  -- Trial fields
  trial_started_at            timestamptz,
  trial_ends_at               timestamptz,
  trial_extended              boolean not null default false,

  -- Paid period fields (populated on first conversion)
  current_period_starts_at    timestamptz,
  current_period_ends_at      timestamptz,

  -- Lifecycle
  cancelled_at                timestamptz,

  -- Discount linkage. One discount per subscription at a time. discount_expires_at is
  -- denormalised for fast filtering ("which subs have an active discount today?") — it
  -- is computed by application code as discount_starts_at + discounts.duration_months.
  applied_discount_id         uuid references public.discounts(id),
  discount_starts_at          timestamptz,
  discount_expires_at         timestamptz,

  created_at                  timestamptz not null default now(),
  updated_at                  timestamptz not null default now(),

  -- Integrity: discount fields must all be set together or all null.
  constraint subscription_discount_consistency check (
    (applied_discount_id is null and discount_starts_at is null and discount_expires_at is null)
    or
    (applied_discount_id is not null and discount_starts_at is not null and discount_expires_at is not null)
  )
);

comment on table public.subscriptions is
  'One subscription per tenant (unique tenant_id). Trial state is the default on creation. Conversion to active sets current_period_*. Cancellation sets cancelled_at; access continues until current_period_ends_at then status flips to expired.';

create index idx_subscriptions_status              on public.subscriptions (status);
create index idx_subscriptions_trial_ends_at       on public.subscriptions (trial_ends_at)         where status = 'trial';
create index idx_subscriptions_discount_expires_at on public.subscriptions (discount_expires_at)   where applied_discount_id is not null;

-- ───────────────────────────────────────────────────────────────────────
-- subscription_addons — which addons each subscription has enabled
-- ───────────────────────────────────────────────────────────────────────

create table public.subscription_addons (
  id              uuid primary key default gen_random_uuid(),
  subscription_id uuid not null references public.subscriptions(id) on delete cascade,
  addon_id        uuid not null references public.addons(id),
  quantity        int not null default 1 check (quantity >= 1),
  enabled         boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (subscription_id, addon_id)
);

comment on table public.subscription_addons is
  'Active add-ons per subscription. Quantity matters for per_unit pricing (e.g. 3 extra staff seats). Disabled rows preserve history rather than being deleted.';

create index idx_subscription_addons_sub on public.subscription_addons (subscription_id) where enabled = true;

-- ───────────────────────────────────────────────────────────────────────
-- updated_at triggers — keep updated_at fresh on every UPDATE without
-- the SPA having to set it explicitly.
-- ───────────────────────────────────────────────────────────────────────

create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger plans_set_updated_at                before update on public.plans                for each row execute function public.tg_set_updated_at();
create trigger addons_set_updated_at               before update on public.addons               for each row execute function public.tg_set_updated_at();
create trigger discounts_set_updated_at            before update on public.discounts            for each row execute function public.tg_set_updated_at();
create trigger subscriptions_set_updated_at        before update on public.subscriptions        for each row execute function public.tg_set_updated_at();
create trigger subscription_addons_set_updated_at  before update on public.subscription_addons  for each row execute function public.tg_set_updated_at();

-- ───────────────────────────────────────────────────────────────────────
-- RLS — enable on all five tables
-- ───────────────────────────────────────────────────────────────────────
-- Pattern:
--   plans, addons, discounts: catalogue tables, world-readable to authenticated
--     users (anyone signed in can see what's on offer). Writes are service-role
--     only — administered out of band, never from the SPA.
--   subscriptions, subscription_addons: tenant-scoped, kennel_owner-only read.
--     Carers (kennel_staff) and owners (pet_owner) cannot see billing details.
--     Writes are service-role only — managed by Edge Functions wrapping
--     Stripe webhooks, not direct SPA writes.
-- ───────────────────────────────────────────────────────────────────────

alter table public.plans                enable row level security;
alter table public.addons               enable row level security;
alter table public.discounts            enable row level security;
alter table public.subscriptions        enable row level security;
alter table public.subscription_addons  enable row level security;

-- Catalogue tables: read for any authenticated user (filtered to active rows).
create policy plans_read_authenticated     on public.plans
  for select to authenticated using (is_active = true);

create policy addons_read_authenticated    on public.addons
  for select to authenticated using (is_active = true);

create policy discounts_read_authenticated on public.discounts
  for select to authenticated using (is_active = true);

-- Subscription read policy: tenant-scoped AND kennel_owner-only.
-- The double-condition means a carer signing in won't see billing data even
-- if they're on the right tenant. Pet owners likewise blocked.
create policy subscriptions_read_owner_only on public.subscriptions
  for select to authenticated
  using (
    tenant_id = nullif(auth.jwt() ->> 'tenant_id', '')::uuid
    and (auth.jwt() ->> 'app_role') = 'kennel_owner'
  );

create policy subscription_addons_read_owner_only on public.subscription_addons
  for select to authenticated
  using (
    (auth.jwt() ->> 'app_role') = 'kennel_owner'
    and exists (
      select 1 from public.subscriptions s
      where s.id = subscription_addons.subscription_id
        and s.tenant_id = nullif(auth.jwt() ->> 'tenant_id', '')::uuid
    )
  );

-- No INSERT/UPDATE/DELETE policies for any role — only service_role can write
-- (which bypasses RLS by design). This is intentional: subscription state is
-- managed server-side via Edge Functions, never directly from the SPA.

-- ============================================================================
-- 20260101000003 — Baseline: tables
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- All 28 tables in the public schema, with column definitions only.
-- Constraints (PK, FK, UNIQUE, CHECK) are added separately in migration
-- 20260101000004 to keep dependency ordering clean.

-- ─────────────────────────────────────────
-- addons
-- ─────────────────────────────────────────
create table if not exists public.addons (
  id uuid not null default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  pricing_model addon_pricing_model not null,
  price_pence integer,
  unit_price_pence integer,
  unit_label text,
  percent_rate numeric(6,3),
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- audit_log
-- ─────────────────────────────────────────
create table if not exists public.audit_log (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  occurred_at timestamp with time zone not null default now(),
  actor_user_id uuid,
  actor_staff_id uuid,
  actor_label text,
  action text not null,
  entity_table text,
  entity_id text,
  details jsonb not null default '{}'::jsonb
);

-- ─────────────────────────────────────────
-- behaviour_alerts
-- ─────────────────────────────────────────
create table if not exists public.behaviour_alerts (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  alert_type behaviour_alert_type not null,
  note text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- booking_pets
-- ─────────────────────────────────────────
create table if not exists public.booking_pets (
  booking_id uuid not null,
  pet_id uuid not null,
  tenant_id uuid not null,
  suite_id uuid
);

-- ─────────────────────────────────────────
-- bookings
-- ─────────────────────────────────────────
create table if not exists public.bookings (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_owner_id uuid not null,
  status booking_status not null default 'pending'::booking_status,
  checkin_date date not null,
  checkout_date date not null,
  checkin_time time without time zone,
  checkout_time time without time zone,
  notes text,
  source text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- daily_updates
-- ─────────────────────────────────────────
create table if not exists public.daily_updates (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  stay_id uuid,
  update_date date not null,
  body text not null,
  photo_paths jsonb not null default '[]'::jsonb,
  written_by uuid,
  staff_id uuid,
  is_owner_visible boolean not null default true,
  sent_to_owner_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- discounts
-- ─────────────────────────────────────────
create table if not exists public.discounts (
  id uuid not null default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  percent_off numeric(5,2) not null,
  duration_months integer not null,
  valid_from timestamp with time zone,
  valid_until timestamp with time zone,
  max_redemptions integer,
  redemption_count integer not null default 0,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- email_outbox
-- ─────────────────────────────────────────
create table if not exists public.email_outbox (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  email_type text not null,
  entity_type text not null,
  entity_id text not null,
  to_email text not null,
  to_name text,
  from_email text not null,
  from_name text not null,
  payload jsonb not null default '{}'::jsonb,
  status text not null default 'pending'::text,
  attempts integer not null default 0,
  last_attempt_at timestamp with time zone,
  sent_at timestamp with time zone,
  failed_at timestamp with time zone,
  error_message text,
  resend_id text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  created_by uuid,
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- invoice_lines
-- ─────────────────────────────────────────
create table if not exists public.invoice_lines (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  invoice_id uuid not null,
  description text not null,
  quantity numeric(10,2) not null default 1,
  unit_price_cents integer not null,
  tax_rate numeric(5,2) not null default 0,
  line_total_cents integer not null,
  line_tax_cents integer not null default 0,
  display_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- invoices
-- ─────────────────────────────────────────
create table if not exists public.invoices (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_owner_id uuid not null,
  booking_id uuid,
  stay_id uuid,
  invoice_number text not null,
  status invoice_status not null default 'draft'::invoice_status,
  issue_date date,
  due_date date,
  currency_code text not null,
  subtotal_cents integer not null default 0,
  tax_cents integer not null default 0,
  total_cents integer not null default 0,
  paid_cents integer not null default 0,
  notes text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- medication_administrations
-- ─────────────────────────────────────────
create table if not exists public.medication_administrations (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  medication_id uuid not null,
  pet_id uuid not null,
  given_at timestamp with time zone not null default now(),
  given_by uuid,
  staff_id uuid,
  notes text,
  created_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- medications
-- ─────────────────────────────────────────
create table if not exists public.medications (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  stay_id uuid,
  med_name text not null,
  dose text,
  frequency text,
  start_date date,
  end_date date,
  notes text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- payments
-- ─────────────────────────────────────────
create table if not exists public.payments (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  invoice_id uuid not null,
  pet_owner_id uuid not null,
  amount_cents integer not null,
  currency_code text not null,
  method payment_method not null,
  paid_at timestamp with time zone not null default now(),
  reference text,
  notes text,
  recorded_by uuid,
  created_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- pet_owners
-- ─────────────────────────────────────────
create table if not exists public.pet_owners (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  display_name text not null,
  email text,
  phone text,
  address_line1 text,
  address_line2 text,
  city text,
  postcode text,
  country text,
  emergency_contact_name text,
  emergency_contact_phone text,
  notes text,
  user_id uuid,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone,
  anonymised_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- pets
-- ─────────────────────────────────────────
create table if not exists public.pets (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_owner_id uuid not null,
  species pet_species not null,
  name text not null,
  emoji text,
  breed text,
  date_of_birth date,
  age_text text,
  sex pet_sex not null default 'unknown'::pet_sex,
  weight_grams integer,
  microchip_id text,
  pet_passport_no text,
  temperament text,
  diet text,
  allergies text,
  meds_summary text,
  vet_name text,
  vet_phone text,
  behaviour_notes text,
  belongings jsonb not null default '[]'::jsonb,
  primary_photo_path text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- plans
-- ─────────────────────────────────────────
create table if not exists public.plans (
  id uuid not null default gen_random_uuid(),
  code text not null,
  name text not null,
  description text,
  run_limit integer not null,
  monthly_price_pence integer not null,
  annual_price_pence integer not null,
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- sites
-- ─────────────────────────────────────────
create table if not exists public.sites (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  name text not null,
  address_line1 text,
  address_line2 text,
  city text,
  region text,
  postcode text,
  country text not null default 'GB'::text,
  phone text,
  email text,
  is_primary boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- staff_members
-- ─────────────────────────────────────────
create table if not exists public.staff_members (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  display_name text not null,
  email text,
  user_id uuid,
  pin_hash text,
  is_active boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- stays
-- ─────────────────────────────────────────
create table if not exists public.stays (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  suite_id uuid not null,
  booking_id uuid,
  status stay_status not null default 'checked_in'::stay_status,
  checkin_at timestamp with time zone not null,
  checkout_at timestamp with time zone,
  notes text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- subscription_addons
-- ─────────────────────────────────────────
create table if not exists public.subscription_addons (
  id uuid not null default gen_random_uuid(),
  subscription_id uuid not null,
  addon_id uuid not null,
  quantity integer not null default 1,
  enabled boolean not null default true,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- subscriptions
-- ─────────────────────────────────────────
create table if not exists public.subscriptions (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  plan_id uuid not null,
  billing_cycle billing_cycle not null default 'monthly'::billing_cycle,
  status subscription_status not null default 'trial'::subscription_status,
  trial_started_at timestamp with time zone,
  trial_ends_at timestamp with time zone,
  trial_extended boolean not null default false,
  current_period_starts_at timestamp with time zone,
  current_period_ends_at timestamp with time zone,
  cancelled_at timestamp with time zone,
  applied_discount_id uuid,
  discount_starts_at timestamp with time zone,
  discount_expires_at timestamp with time zone,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- suites
-- ─────────────────────────────────────────
create table if not exists public.suites (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  site_id uuid not null,
  species pet_species not null,
  name text not null,
  short_code text,
  kind suite_kind not null default 'standard'::suite_kind,
  status suite_status not null default 'available'::suite_status,
  booking_enabled boolean not null default true,
  display_order integer not null default 0,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- tenant_settings
-- ─────────────────────────────────────────
create table if not exists public.tenant_settings (
  tenant_id uuid not null,
  setting_key text not null,
  setting_value jsonb not null,
  updated_at timestamp with time zone not null default now()
);

-- ─────────────────────────────────────────
-- tenants
-- ─────────────────────────────────────────
create table if not exists public.tenants (
  id uuid not null default gen_random_uuid(),
  slug text not null,
  name text not null,
  region text not null default 'GB'::text,
  currency_code text not null default 'GBP'::text,
  currency_symbol text not null default '£'::text,
  currency_position text not null default 'before'::text,
  tax_label text not null default 'VAT'::text,
  tax_rate numeric(5,2) not null default 20.00,
  tax_inclusive boolean not null default true,
  tax_number text,
  language text not null default 'en'::text,
  weight_unit text not null default 'kg'::text,
  date_format text not null default 'DD/MM/YYYY'::text,
  time_format text not null default '24h'::text,
  timezone text not null default 'Europe/London'::text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone,
  email_from text,
  email_from_name text,
  privacy_notice text,
  privacy_notice_updated_at timestamp with time zone,
  is_demo boolean not null default false,
  setup_completed_at timestamp with time zone,
  run_count integer not null default 0,
  cattery_count integer not null default 0
);

-- ─────────────────────────────────────────
-- user_profiles
-- ─────────────────────────────────────────
create table if not exists public.user_profiles (
  id uuid not null,
  tenant_id uuid not null,
  role user_role not null,
  display_name text,
  email text,
  staff_id uuid,
  pet_owner_id uuid,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- vaccination_records
-- ─────────────────────────────────────────
create table if not exists public.vaccination_records (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  vaccine_code text not null,
  vaccine_label text not null,
  administered_on date,
  expires_on date,
  status vaccination_status not null default 'unknown'::vaccination_status,
  evidence_path text,
  notes text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- wellbeing_entries
-- ─────────────────────────────────────────
create table if not exists public.wellbeing_entries (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  pet_id uuid not null,
  stay_id uuid,
  entry_date date not null,
  appetite_score smallint,
  toileting_score smallint,
  health_score smallint,
  appetite_note text,
  toileting_note text,
  health_note text,
  recorded_by uuid,
  staff_id uuid,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  deleted_at timestamp with time zone
);

-- ─────────────────────────────────────────
-- yjs_snapshots
-- ─────────────────────────────────────────
create table if not exists public.yjs_snapshots (
  id uuid not null default gen_random_uuid(),
  tenant_id uuid not null,
  doc bytea not null,
  doc_size_bytes integer not null,
  version integer not null,
  reason text,
  created_at timestamp with time zone not null default now(),
  created_by uuid
);


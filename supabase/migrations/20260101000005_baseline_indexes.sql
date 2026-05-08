-- ============================================================================
-- 20260101000005 — Baseline: indexes
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- All non-PK indexes in the public schema. Primary key indexes are auto-created
-- by the PK constraints in migration 20260101000004 — including them here
-- would conflict on a fresh apply, so they're filtered out.

-- ─── addons ───
CREATE UNIQUE INDEX addons_code_key ON public.addons USING btree (code);

-- ─── audit_log ───
CREATE INDEX audit_log_action_idx ON public.audit_log USING btree (tenant_id, action, occurred_at DESC);
CREATE INDEX audit_log_entity_idx ON public.audit_log USING btree (tenant_id, entity_table, entity_id) WHERE (entity_id IS NOT NULL);
CREATE INDEX audit_log_tenant_time_idx ON public.audit_log USING btree (tenant_id, occurred_at DESC);

-- ─── behaviour_alerts ───
CREATE INDEX behaviour_alerts_pet_idx ON public.behaviour_alerts USING btree (tenant_id, pet_id) WHERE ((deleted_at IS NULL) AND is_active);
CREATE UNIQUE INDEX behaviour_alerts_tenant_id_pet_id_alert_type_key ON public.behaviour_alerts USING btree (tenant_id, pet_id, alert_type);
CREATE INDEX behaviour_alerts_tenant_idx ON public.behaviour_alerts USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── booking_pets ───
CREATE INDEX booking_pets_pet_idx ON public.booking_pets USING btree (tenant_id, pet_id);
CREATE INDEX booking_pets_tenant_idx ON public.booking_pets USING btree (tenant_id);

-- ─── bookings ───
CREATE INDEX bookings_dates_idx ON public.bookings USING btree (tenant_id, checkin_date, checkout_date) WHERE (deleted_at IS NULL);
CREATE INDEX bookings_owner_idx ON public.bookings USING btree (tenant_id, pet_owner_id) WHERE (deleted_at IS NULL);
CREATE INDEX bookings_status_idx ON public.bookings USING btree (tenant_id, status) WHERE (deleted_at IS NULL);
CREATE INDEX bookings_tenant_idx ON public.bookings USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── daily_updates ───
CREATE INDEX daily_updates_pet_date_idx ON public.daily_updates USING btree (tenant_id, pet_id, update_date) WHERE (deleted_at IS NULL);
CREATE INDEX daily_updates_tenant_idx ON public.daily_updates USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── discounts ───
CREATE UNIQUE INDEX discounts_code_key ON public.discounts USING btree (code);

-- ─── email_outbox ───
CREATE INDEX email_outbox_entity_idx ON public.email_outbox USING btree (tenant_id, entity_type, entity_id, email_type, created_at DESC) WHERE (deleted_at IS NULL);
CREATE INDEX email_outbox_pending_idx ON public.email_outbox USING btree (tenant_id, status, created_at) WHERE ((status = ANY (ARRAY['pending'::text, 'failed'::text])) AND (deleted_at IS NULL));
CREATE INDEX email_outbox_tenant_idx ON public.email_outbox USING btree (tenant_id, created_at DESC) WHERE (deleted_at IS NULL);

-- ─── invoice_lines ───
CREATE INDEX invoice_lines_invoice_idx ON public.invoice_lines USING btree (invoice_id);
CREATE INDEX invoice_lines_tenant_idx ON public.invoice_lines USING btree (tenant_id);

-- ─── invoices ───
CREATE INDEX invoices_issue_date_idx ON public.invoices USING btree (tenant_id, issue_date DESC) WHERE (deleted_at IS NULL);
CREATE INDEX invoices_owner_idx ON public.invoices USING btree (tenant_id, pet_owner_id) WHERE (deleted_at IS NULL);
CREATE INDEX invoices_status_idx ON public.invoices USING btree (tenant_id, status) WHERE (deleted_at IS NULL);
CREATE UNIQUE INDEX invoices_tenant_id_invoice_number_key ON public.invoices USING btree (tenant_id, invoice_number);
CREATE INDEX invoices_tenant_idx ON public.invoices USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── medication_administrations ───
CREATE INDEX med_admin_pet_time_idx ON public.medication_administrations USING btree (tenant_id, pet_id, given_at DESC);
CREATE INDEX med_admin_tenant_idx ON public.medication_administrations USING btree (tenant_id);

-- ─── medications ───
CREATE INDEX medications_pet_idx ON public.medications USING btree (tenant_id, pet_id) WHERE ((deleted_at IS NULL) AND is_active);
CREATE INDEX medications_tenant_idx ON public.medications USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── payments ───
CREATE INDEX payments_invoice_idx ON public.payments USING btree (tenant_id, invoice_id);
CREATE INDEX payments_owner_idx ON public.payments USING btree (tenant_id, pet_owner_id);
CREATE INDEX payments_paid_at_idx ON public.payments USING btree (tenant_id, paid_at DESC);
CREATE INDEX payments_tenant_idx ON public.payments USING btree (tenant_id);

-- ─── pet_owners ───
CREATE INDEX pet_owners_anonymised_idx ON public.pet_owners USING btree (tenant_id, anonymised_at) WHERE (anonymised_at IS NOT NULL);
CREATE INDEX pet_owners_email_idx ON public.pet_owners USING btree (tenant_id, email) WHERE ((email IS NOT NULL) AND (deleted_at IS NULL));
CREATE INDEX pet_owners_tenant_idx ON public.pet_owners USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── pets ───
CREATE INDEX pets_microchip_idx ON public.pets USING btree (microchip_id) WHERE (microchip_id IS NOT NULL);
CREATE INDEX pets_name_trgm_idx ON public.pets USING gin (name gin_trgm_ops);
CREATE INDEX pets_owner_idx ON public.pets USING btree (tenant_id, pet_owner_id) WHERE (deleted_at IS NULL);
CREATE INDEX pets_species_idx ON public.pets USING btree (tenant_id, species) WHERE (deleted_at IS NULL);
CREATE INDEX pets_tenant_idx ON public.pets USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── plans ───
CREATE INDEX idx_plans_active_sort ON public.plans USING btree (is_active, sort_order) WHERE (is_active = true);
CREATE UNIQUE INDEX plans_code_key ON public.plans USING btree (code);

-- ─── sites ───
CREATE INDEX sites_tenant_idx ON public.sites USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── staff_members ───
CREATE INDEX staff_tenant_idx ON public.staff_members USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── stays ───
CREATE INDEX stays_pet_idx ON public.stays USING btree (tenant_id, pet_id) WHERE (deleted_at IS NULL);
CREATE INDEX stays_status_idx ON public.stays USING btree (tenant_id, status) WHERE (deleted_at IS NULL);
CREATE INDEX stays_suite_idx ON public.stays USING btree (tenant_id, suite_id) WHERE (deleted_at IS NULL);
CREATE INDEX stays_tenant_idx ON public.stays USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── subscription_addons ───
CREATE INDEX idx_subscription_addons_sub ON public.subscription_addons USING btree (subscription_id) WHERE (enabled = true);
CREATE UNIQUE INDEX subscription_addons_subscription_id_addon_id_key ON public.subscription_addons USING btree (subscription_id, addon_id);

-- ─── subscriptions ───
CREATE INDEX idx_subscriptions_discount_expires_at ON public.subscriptions USING btree (discount_expires_at) WHERE (applied_discount_id IS NOT NULL);
CREATE INDEX idx_subscriptions_status ON public.subscriptions USING btree (status);
CREATE INDEX idx_subscriptions_trial_ends_at ON public.subscriptions USING btree (trial_ends_at) WHERE (status = 'trial'::subscription_status);
CREATE UNIQUE INDEX subscriptions_tenant_id_key ON public.subscriptions USING btree (tenant_id);

-- ─── suites ───
CREATE UNIQUE INDEX suites_short_code_idx ON public.suites USING btree (tenant_id, short_code) WHERE ((short_code IS NOT NULL) AND (deleted_at IS NULL));
CREATE INDEX suites_site_idx ON public.suites USING btree (tenant_id, site_id) WHERE (deleted_at IS NULL);
CREATE INDEX suites_species_idx ON public.suites USING btree (tenant_id, species) WHERE (deleted_at IS NULL);
CREATE INDEX suites_tenant_idx ON public.suites USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── tenants ───
CREATE INDEX tenants_is_demo_idx ON public.tenants USING btree (is_demo) WHERE (is_demo IS TRUE);
CREATE UNIQUE INDEX tenants_slug_key ON public.tenants USING btree (slug);

-- ─── user_profiles ───
CREATE INDEX user_profiles_role_idx ON public.user_profiles USING btree (tenant_id, role) WHERE (deleted_at IS NULL);
CREATE INDEX user_profiles_tenant_idx ON public.user_profiles USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── vaccination_records ───
CREATE INDEX vaccinations_expires_idx ON public.vaccination_records USING btree (tenant_id, expires_on) WHERE ((expires_on IS NOT NULL) AND (deleted_at IS NULL));
CREATE INDEX vaccinations_pet_idx ON public.vaccination_records USING btree (tenant_id, pet_id) WHERE (deleted_at IS NULL);
CREATE INDEX vaccinations_tenant_idx ON public.vaccination_records USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── wellbeing_entries ───
CREATE UNIQUE INDEX wellbeing_entries_tenant_id_pet_id_entry_date_key ON public.wellbeing_entries USING btree (tenant_id, pet_id, entry_date);
CREATE INDEX wellbeing_pet_date_idx ON public.wellbeing_entries USING btree (tenant_id, pet_id, entry_date DESC) WHERE (deleted_at IS NULL);
CREATE INDEX wellbeing_tenant_idx ON public.wellbeing_entries USING btree (tenant_id) WHERE (deleted_at IS NULL);

-- ─── yjs_snapshots ───
CREATE INDEX yjs_snapshots_created_idx ON public.yjs_snapshots USING btree (tenant_id, created_at DESC);
CREATE INDEX yjs_snapshots_tenant_version_idx ON public.yjs_snapshots USING btree (tenant_id, version DESC);


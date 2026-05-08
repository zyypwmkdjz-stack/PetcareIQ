-- ============================================================================
-- 20260101000004 — Baseline: constraints (PK, FK, UNIQUE, CHECK)
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- All constraints across all tables. Applied as ALTER TABLE statements
-- so they can be added in any order without dependency loops.
-- Order within file: PK first, then UNIQUE, then CHECK, then FK
-- (FKs depend on the PKs of other tables already existing).


-- ─────────────────────────────────────────
-- PRIMARY KEY
-- ─────────────────────────────────────────
alter table public.addons add constraint addons_pkey PRIMARY KEY (id);
alter table public.audit_log add constraint audit_log_pkey PRIMARY KEY (id);
alter table public.behaviour_alerts add constraint behaviour_alerts_pkey PRIMARY KEY (id);
alter table public.booking_pets add constraint booking_pets_pkey PRIMARY KEY (booking_id, pet_id);
alter table public.bookings add constraint bookings_pkey PRIMARY KEY (id);
alter table public.daily_updates add constraint daily_updates_pkey PRIMARY KEY (id);
alter table public.discounts add constraint discounts_pkey PRIMARY KEY (id);
alter table public.email_outbox add constraint email_outbox_pkey PRIMARY KEY (id);
alter table public.invoice_lines add constraint invoice_lines_pkey PRIMARY KEY (id);
alter table public.invoices add constraint invoices_pkey PRIMARY KEY (id);
alter table public.medication_administrations add constraint medication_administrations_pkey PRIMARY KEY (id);
alter table public.medications add constraint medications_pkey PRIMARY KEY (id);
alter table public.payments add constraint payments_pkey PRIMARY KEY (id);
alter table public.pet_owners add constraint pet_owners_pkey PRIMARY KEY (id);
alter table public.pets add constraint pets_pkey PRIMARY KEY (id);
alter table public.plans add constraint plans_pkey PRIMARY KEY (id);
alter table public.sites add constraint sites_pkey PRIMARY KEY (id);
alter table public.staff_members add constraint staff_members_pkey PRIMARY KEY (id);
alter table public.stays add constraint stays_pkey PRIMARY KEY (id);
alter table public.subscription_addons add constraint subscription_addons_pkey PRIMARY KEY (id);
alter table public.subscriptions add constraint subscriptions_pkey PRIMARY KEY (id);
alter table public.suites add constraint suites_pkey PRIMARY KEY (id);
alter table public.tenant_settings add constraint tenant_settings_pkey PRIMARY KEY (tenant_id, setting_key);
alter table public.tenants add constraint tenants_pkey PRIMARY KEY (id);
alter table public.user_profiles add constraint user_profiles_pkey PRIMARY KEY (id);
alter table public.vaccination_records add constraint vaccination_records_pkey PRIMARY KEY (id);
alter table public.wellbeing_entries add constraint wellbeing_entries_pkey PRIMARY KEY (id);
alter table public.yjs_snapshots add constraint yjs_snapshots_pkey PRIMARY KEY (id);

-- ─────────────────────────────────────────
-- UNIQUE
-- ─────────────────────────────────────────
alter table public.addons add constraint addons_code_key UNIQUE (code);
alter table public.behaviour_alerts add constraint behaviour_alerts_tenant_id_pet_id_alert_type_key UNIQUE (tenant_id, pet_id, alert_type) DEFERRABLE INITIALLY DEFERRED;
alter table public.discounts add constraint discounts_code_key UNIQUE (code);
alter table public.invoices add constraint invoices_tenant_id_invoice_number_key UNIQUE (tenant_id, invoice_number);
alter table public.plans add constraint plans_code_key UNIQUE (code);
alter table public.subscription_addons add constraint subscription_addons_subscription_id_addon_id_key UNIQUE (subscription_id, addon_id);
alter table public.subscriptions add constraint subscriptions_tenant_id_key UNIQUE (tenant_id);
alter table public.tenants add constraint tenants_slug_key UNIQUE (slug);
alter table public.wellbeing_entries add constraint wellbeing_entries_tenant_id_pet_id_entry_date_key UNIQUE (tenant_id, pet_id, entry_date) DEFERRABLE INITIALLY DEFERRED;

-- ─────────────────────────────────────────
-- CHECK
-- ─────────────────────────────────────────
alter table public.addons add constraint addon_pricing_model_consistency CHECK ((((pricing_model = 'flat_monthly'::addon_pricing_model) AND (price_pence IS NOT NULL) AND (unit_price_pence IS NULL) AND (percent_rate IS NULL)) OR ((pricing_model = 'per_unit'::addon_pricing_model) AND (unit_price_pence IS NOT NULL) AND (unit_label IS NOT NULL) AND (price_pence IS NULL) AND (percent_rate IS NULL)) OR ((pricing_model = 'percentage_passthrough'::addon_pricing_model) AND (percent_rate IS NOT NULL) AND (price_pence IS NULL) AND (unit_price_pence IS NULL))));
alter table public.bookings add constraint bookings_check CHECK ((checkout_date >= checkin_date));
alter table public.discounts add constraint discounts_duration_months_check CHECK ((duration_months > 0));
alter table public.discounts add constraint discounts_max_redemptions_check CHECK (((max_redemptions IS NULL) OR (max_redemptions > 0)));
alter table public.discounts add constraint discounts_percent_off_check CHECK (((percent_off > (0)::numeric) AND (percent_off <= (100)::numeric)));
alter table public.discounts add constraint discounts_redemption_count_check CHECK ((redemption_count >= 0));
alter table public.email_outbox add constraint email_outbox_email_type_check CHECK ((email_type = ANY (ARRAY['booking_confirmed'::text, 'booking_declined'::text, 'amend_approved'::text, 'amend_declined'::text])));
alter table public.email_outbox add constraint email_outbox_entity_type_check CHECK ((entity_type = 'booking'::text));
alter table public.email_outbox add constraint email_outbox_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'failed'::text, 'cancelled'::text])));
alter table public.plans add constraint plans_annual_price_pence_check CHECK ((annual_price_pence >= 0));
alter table public.plans add constraint plans_monthly_price_pence_check CHECK ((monthly_price_pence >= 0));
alter table public.plans add constraint plans_run_limit_check CHECK ((run_limit > 0));
alter table public.subscription_addons add constraint subscription_addons_quantity_check CHECK ((quantity >= 1));
alter table public.subscriptions add constraint subscription_discount_consistency CHECK ((((applied_discount_id IS NULL) AND (discount_starts_at IS NULL) AND (discount_expires_at IS NULL)) OR ((applied_discount_id IS NOT NULL) AND (discount_starts_at IS NOT NULL) AND (discount_expires_at IS NOT NULL))));
alter table public.tenants add constraint tenants_cattery_count_check CHECK ((cattery_count >= 0));
alter table public.tenants add constraint tenants_currency_position_check CHECK ((currency_position = ANY (ARRAY['before'::text, 'after'::text])));
alter table public.tenants add constraint tenants_run_count_check CHECK ((run_count >= 0));
alter table public.tenants add constraint tenants_time_format_check CHECK ((time_format = ANY (ARRAY['24h'::text, '12h'::text])));
alter table public.tenants add constraint tenants_weight_unit_check CHECK ((weight_unit = ANY (ARRAY['kg'::text, 'lb'::text])));
alter table public.wellbeing_entries add constraint wellbeing_entries_appetite_score_check CHECK (((appetite_score >= 0) AND (appetite_score <= 2)));
alter table public.wellbeing_entries add constraint wellbeing_entries_health_score_check CHECK (((health_score >= 0) AND (health_score <= 2)));
alter table public.wellbeing_entries add constraint wellbeing_entries_toileting_score_check CHECK (((toileting_score >= 0) AND (toileting_score <= 2)));

-- ─────────────────────────────────────────
-- FOREIGN KEY
-- ─────────────────────────────────────────
alter table public.audit_log add constraint audit_log_actor_staff_id_fkey FOREIGN KEY (actor_staff_id) REFERENCES staff_members(id) ON DELETE SET NULL;
alter table public.audit_log add constraint audit_log_actor_user_id_fkey FOREIGN KEY (actor_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.audit_log add constraint audit_log_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.behaviour_alerts add constraint behaviour_alerts_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE;
alter table public.behaviour_alerts add constraint behaviour_alerts_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.booking_pets add constraint booking_pets_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE;
alter table public.booking_pets add constraint booking_pets_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE RESTRICT;
alter table public.booking_pets add constraint booking_pets_suite_id_fkey FOREIGN KEY (suite_id) REFERENCES suites(id) ON DELETE SET NULL;
alter table public.booking_pets add constraint booking_pets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.bookings add constraint bookings_pet_owner_id_fkey FOREIGN KEY (pet_owner_id) REFERENCES pet_owners(id) ON DELETE RESTRICT;
alter table public.bookings add constraint bookings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.daily_updates add constraint daily_updates_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE RESTRICT;
alter table public.daily_updates add constraint daily_updates_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff_members(id);
alter table public.daily_updates add constraint daily_updates_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES stays(id) ON DELETE SET NULL;
alter table public.daily_updates add constraint daily_updates_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.daily_updates add constraint daily_updates_written_by_fkey FOREIGN KEY (written_by) REFERENCES auth.users(id);
alter table public.email_outbox add constraint email_outbox_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);
alter table public.email_outbox add constraint email_outbox_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.invoice_lines add constraint invoice_lines_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE;
alter table public.invoice_lines add constraint invoice_lines_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.invoices add constraint invoices_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;
alter table public.invoices add constraint invoices_pet_owner_id_fkey FOREIGN KEY (pet_owner_id) REFERENCES pet_owners(id) ON DELETE RESTRICT;
alter table public.invoices add constraint invoices_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES stays(id) ON DELETE SET NULL;
alter table public.invoices add constraint invoices_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.medication_administrations add constraint medication_administrations_given_by_fkey FOREIGN KEY (given_by) REFERENCES auth.users(id);
alter table public.medication_administrations add constraint medication_administrations_medication_id_fkey FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE;
alter table public.medication_administrations add constraint medication_administrations_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE;
alter table public.medication_administrations add constraint medication_administrations_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff_members(id);
alter table public.medication_administrations add constraint medication_administrations_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.medications add constraint medications_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE;
alter table public.medications add constraint medications_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES stays(id) ON DELETE SET NULL;
alter table public.medications add constraint medications_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.payments add constraint payments_invoice_id_fkey FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE RESTRICT;
alter table public.payments add constraint payments_pet_owner_id_fkey FOREIGN KEY (pet_owner_id) REFERENCES pet_owners(id) ON DELETE RESTRICT;
alter table public.payments add constraint payments_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES auth.users(id);
alter table public.payments add constraint payments_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.pet_owners add constraint pet_owners_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.pet_owners add constraint pet_owners_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.pets add constraint pets_pet_owner_id_fkey FOREIGN KEY (pet_owner_id) REFERENCES pet_owners(id) ON DELETE RESTRICT;
alter table public.pets add constraint pets_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.sites add constraint sites_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.staff_members add constraint staff_members_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.staff_members add constraint staff_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.stays add constraint stays_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE SET NULL;
alter table public.stays add constraint stays_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE RESTRICT;
alter table public.stays add constraint stays_suite_id_fkey FOREIGN KEY (suite_id) REFERENCES suites(id) ON DELETE RESTRICT;
alter table public.stays add constraint stays_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.subscription_addons add constraint subscription_addons_addon_id_fkey FOREIGN KEY (addon_id) REFERENCES addons(id);
alter table public.subscription_addons add constraint subscription_addons_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES subscriptions(id) ON DELETE CASCADE;
alter table public.subscriptions add constraint subscriptions_applied_discount_id_fkey FOREIGN KEY (applied_discount_id) REFERENCES discounts(id);
alter table public.subscriptions add constraint subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES plans(id);
alter table public.subscriptions add constraint subscriptions_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.suites add constraint suites_site_id_fkey FOREIGN KEY (site_id) REFERENCES sites(id) ON DELETE RESTRICT;
alter table public.suites add constraint suites_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.tenant_settings add constraint tenant_settings_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.user_profiles add constraint user_profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
alter table public.user_profiles add constraint user_profiles_pet_owner_fk FOREIGN KEY (pet_owner_id) REFERENCES pet_owners(id) ON DELETE SET NULL;
alter table public.user_profiles add constraint user_profiles_staff_fk FOREIGN KEY (staff_id) REFERENCES staff_members(id) ON DELETE SET NULL;
alter table public.user_profiles add constraint user_profiles_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.vaccination_records add constraint vaccination_records_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE;
alter table public.vaccination_records add constraint vaccination_records_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.wellbeing_entries add constraint wellbeing_entries_pet_id_fkey FOREIGN KEY (pet_id) REFERENCES pets(id) ON DELETE CASCADE;
alter table public.wellbeing_entries add constraint wellbeing_entries_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES auth.users(id);
alter table public.wellbeing_entries add constraint wellbeing_entries_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES staff_members(id);
alter table public.wellbeing_entries add constraint wellbeing_entries_stay_id_fkey FOREIGN KEY (stay_id) REFERENCES stays(id) ON DELETE SET NULL;
alter table public.wellbeing_entries add constraint wellbeing_entries_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;
alter table public.yjs_snapshots add constraint yjs_snapshots_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
alter table public.yjs_snapshots add constraint yjs_snapshots_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES tenants(id) ON DELETE CASCADE;

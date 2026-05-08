-- ============================================================================
-- 20260101000007 — Baseline: RLS policies
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- Row Level Security policies for every table. Each table has RLS enabled
-- followed by the policies that scope reads/writes appropriately.

-- ─── addons ───
alter table public.addons enable row level security;
create policy "addons_read_authenticated" on public.addons as PERMISSIVE for SELECT to authenticated using ((is_active = true));

-- ─── audit_log ───
alter table public.audit_log enable row level security;
create policy "audit_log_tenant_insert" on public.audit_log as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "audit_log_tenant_select" on public.audit_log as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));

-- ─── behaviour_alerts ───
alter table public.behaviour_alerts enable row level security;
create policy "behaviour_alerts_tenant_delete" on public.behaviour_alerts as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "behaviour_alerts_tenant_insert" on public.behaviour_alerts as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "behaviour_alerts_tenant_select" on public.behaviour_alerts as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "behaviour_alerts_tenant_update" on public.behaviour_alerts as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── booking_pets ───
alter table public.booking_pets enable row level security;
create policy "booking_pets_tenant_delete" on public.booking_pets as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "booking_pets_tenant_insert" on public.booking_pets as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "booking_pets_tenant_select" on public.booking_pets as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "booking_pets_tenant_update" on public.booking_pets as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── bookings ───
alter table public.bookings enable row level security;
create policy "bookings_owner_aware_select" on public.bookings as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_owner_id = jwt_pet_owner_id()))));
create policy "bookings_tenant_delete" on public.bookings as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "bookings_tenant_insert" on public.bookings as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "bookings_tenant_update" on public.bookings as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── daily_updates ───
alter table public.daily_updates enable row level security;
create policy "daily_updates_owner_aware_select" on public.daily_updates as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (is_owner_visible AND (pet_id IN ( SELECT pets.id
   FROM pets
  WHERE (pets.pet_owner_id = jwt_pet_owner_id())))))));
create policy "daily_updates_tenant_delete" on public.daily_updates as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "daily_updates_tenant_insert" on public.daily_updates as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "daily_updates_tenant_update" on public.daily_updates as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── discounts ───
alter table public.discounts enable row level security;
create policy "discounts_read_authenticated" on public.discounts as PERMISSIVE for SELECT to authenticated using ((is_active = true));

-- ─── invoice_lines ───
alter table public.invoice_lines enable row level security;
create policy "invoice_lines_owner_aware_select" on public.invoice_lines as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (invoice_id IN ( SELECT invoices.id
   FROM invoices
  WHERE (invoices.pet_owner_id = jwt_pet_owner_id()))))));
create policy "invoice_lines_tenant_delete" on public.invoice_lines as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "invoice_lines_tenant_insert" on public.invoice_lines as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "invoice_lines_tenant_update" on public.invoice_lines as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── invoices ───
alter table public.invoices enable row level security;
create policy "invoices_owner_aware_select" on public.invoices as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_owner_id = jwt_pet_owner_id()))));
create policy "invoices_tenant_delete" on public.invoices as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "invoices_tenant_insert" on public.invoices as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "invoices_tenant_update" on public.invoices as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── medication_administrations ───
alter table public.medication_administrations enable row level security;
create policy "medication_administrations_tenant_insert" on public.medication_administrations as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "medication_administrations_tenant_select" on public.medication_administrations as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));

-- ─── medications ───
alter table public.medications enable row level security;
create policy "medications_tenant_delete" on public.medications as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "medications_tenant_insert" on public.medications as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "medications_tenant_select" on public.medications as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "medications_tenant_update" on public.medications as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── payments ───
alter table public.payments enable row level security;
create policy "payments_owner_aware_select" on public.payments as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_owner_id = jwt_pet_owner_id()))));
create policy "payments_tenant_insert" on public.payments as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── pet_owners ───
alter table public.pet_owners enable row level security;
create policy "pet_owners_owner_aware_select" on public.pet_owners as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (id = jwt_pet_owner_id()))));
create policy "pet_owners_tenant_delete" on public.pet_owners as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "pet_owners_tenant_insert" on public.pet_owners as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "pet_owners_tenant_update" on public.pet_owners as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── pets ───
alter table public.pets enable row level security;
create policy "pets_owner_aware_select" on public.pets as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_owner_id = jwt_pet_owner_id()))));
create policy "pets_tenant_delete" on public.pets as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "pets_tenant_insert" on public.pets as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "pets_tenant_update" on public.pets as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── plans ───
alter table public.plans enable row level security;
create policy "plans_read_authenticated" on public.plans as PERMISSIVE for SELECT to authenticated using ((is_active = true));

-- ─── sites ───
alter table public.sites enable row level security;
create policy "sites_tenant_delete" on public.sites as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "sites_tenant_insert" on public.sites as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "sites_tenant_select" on public.sites as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "sites_tenant_update" on public.sites as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── staff_members ───
alter table public.staff_members enable row level security;
create policy "staff_members_tenant_delete" on public.staff_members as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "staff_members_tenant_insert" on public.staff_members as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "staff_members_tenant_select" on public.staff_members as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "staff_members_tenant_update" on public.staff_members as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── stays ───
alter table public.stays enable row level security;
create policy "stays_owner_aware_select" on public.stays as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_id IN ( SELECT pets.id
   FROM pets
  WHERE (pets.pet_owner_id = jwt_pet_owner_id()))))));
create policy "stays_tenant_delete" on public.stays as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "stays_tenant_insert" on public.stays as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "stays_tenant_update" on public.stays as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── subscription_addons ───
alter table public.subscription_addons enable row level security;
create policy "subscription_addons_read_owner_only" on public.subscription_addons as PERMISSIVE for SELECT to authenticated using ((((auth.jwt() ->> 'app_role'::text) = 'kennel_owner'::text) AND (EXISTS ( SELECT 1
   FROM subscriptions s
  WHERE ((s.id = subscription_addons.subscription_id) AND (s.tenant_id = (NULLIF((auth.jwt() ->> 'tenant_id'::text), ''::text))::uuid))))));

-- ─── subscriptions ───
alter table public.subscriptions enable row level security;
create policy "subscriptions_read_owner_only" on public.subscriptions as PERMISSIVE for SELECT to authenticated using (((tenant_id = (NULLIF((auth.jwt() ->> 'tenant_id'::text), ''::text))::uuid) AND ((auth.jwt() ->> 'app_role'::text) = 'kennel_owner'::text)));

-- ─── suites ───
alter table public.suites enable row level security;
create policy "suites_tenant_delete" on public.suites as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "suites_tenant_insert" on public.suites as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "suites_tenant_select" on public.suites as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "suites_tenant_update" on public.suites as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── tenant_settings ───
alter table public.tenant_settings enable row level security;
create policy "tenant_settings_tenant_delete" on public.tenant_settings as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "tenant_settings_tenant_insert" on public.tenant_settings as PERMISSIVE for INSERT to authenticated with check ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenant_settings.tenant_id)))));
create policy "tenant_settings_tenant_select" on public.tenant_settings as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenant_settings.tenant_id)))));
create policy "tenant_settings_tenant_update" on public.tenant_settings as PERMISSIVE for UPDATE to authenticated using ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenant_settings.tenant_id))))) with check ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenant_settings.tenant_id)))));

-- ─── tenants ───
alter table public.tenants enable row level security;
create policy "Tenant users update their own tenant" on public.tenants as PERMISSIVE for UPDATE to authenticated using ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenants.id))))) with check ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenants.id)))));
create policy "tenants_self_read" on public.tenants as PERMISSIVE for SELECT to authenticated using ((EXISTS ( SELECT 1
   FROM user_profiles
  WHERE ((user_profiles.id = auth.uid()) AND (user_profiles.tenant_id = tenants.id)))));

-- ─── user_profiles ───
alter table public.user_profiles enable row level security;
create policy "user_profiles_tenant_delete" on public.user_profiles as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "user_profiles_tenant_insert" on public.user_profiles as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "user_profiles_tenant_select" on public.user_profiles as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "user_profiles_tenant_update" on public.user_profiles as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── vaccination_records ───
alter table public.vaccination_records enable row level security;
create policy "vaccination_records_tenant_delete" on public.vaccination_records as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "vaccination_records_tenant_insert" on public.vaccination_records as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "vaccination_records_tenant_update" on public.vaccination_records as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "vaccinations_owner_aware_select" on public.vaccination_records as PERMISSIVE for SELECT to public using (((tenant_id = jwt_tenant_id()) AND ((jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])) OR (pet_id IN ( SELECT pets.id
   FROM pets
  WHERE (pets.pet_owner_id = jwt_pet_owner_id()))))));

-- ─── wellbeing_entries ───
alter table public.wellbeing_entries enable row level security;
create policy "wellbeing_entries_tenant_delete" on public.wellbeing_entries as PERMISSIVE for DELETE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = 'kennel_owner'::text)));
create policy "wellbeing_entries_tenant_insert" on public.wellbeing_entries as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "wellbeing_entries_tenant_select" on public.wellbeing_entries as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));
create policy "wellbeing_entries_tenant_update" on public.wellbeing_entries as PERMISSIVE for UPDATE to public using (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text])))) with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));

-- ─── yjs_snapshots ───
alter table public.yjs_snapshots enable row level security;
create policy "yjs_snapshots_tenant_insert" on public.yjs_snapshots as PERMISSIVE for INSERT to public with check (((tenant_id = jwt_tenant_id()) AND (jwt_role() = ANY (ARRAY['kennel_owner'::text, 'kennel_staff'::text]))));
create policy "yjs_snapshots_tenant_select" on public.yjs_snapshots as PERMISSIVE for SELECT to public using ((tenant_id = jwt_tenant_id()));


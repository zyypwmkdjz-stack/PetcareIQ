-- ============================================================================
-- 20260101000006 — Baseline: triggers
-- ----------------------------------------------------------------------------
-- BASELINE MIGRATION — documents schema as of 2026-05-08.
-- DO NOT re-apply against the live database (will error on duplicates).
-- This file is for source-control reproducibility and disaster recovery.
-- ============================================================================

-- All non-internal triggers. Most are updated_at maintenance triggers.

-- ─── addons ───
CREATE TRIGGER addons_set_updated_at BEFORE UPDATE ON public.addons FOR EACH ROW EXECUTE FUNCTION tg_set_updated_at();

-- ─── behaviour_alerts ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.behaviour_alerts FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── bookings ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── daily_updates ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.daily_updates FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── discounts ───
CREATE TRIGGER discounts_set_updated_at BEFORE UPDATE ON public.discounts FOR EACH ROW EXECUTE FUNCTION tg_set_updated_at();

-- ─── invoice_lines ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.invoice_lines FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── invoices ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.invoices FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── medications ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.medications FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── pet_owners ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.pet_owners FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── pets ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.pets FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── plans ───
CREATE TRIGGER plans_set_updated_at BEFORE UPDATE ON public.plans FOR EACH ROW EXECUTE FUNCTION tg_set_updated_at();

-- ─── sites ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.sites FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── staff_members ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.staff_members FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── stays ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.stays FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── subscription_addons ───
CREATE TRIGGER subscription_addons_set_updated_at BEFORE UPDATE ON public.subscription_addons FOR EACH ROW EXECUTE FUNCTION tg_set_updated_at();

-- ─── subscriptions ───
CREATE TRIGGER subscriptions_set_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION tg_set_updated_at();

-- ─── suites ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.suites FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── tenant_settings ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.tenant_settings FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── tenants ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.tenants FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── user_profiles ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── vaccination_records ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.vaccination_records FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- ─── wellbeing_entries ───
CREATE TRIGGER touch_updated_at BEFORE UPDATE ON public.wellbeing_entries FOR EACH ROW EXECUTE FUNCTION touch_updated_at();


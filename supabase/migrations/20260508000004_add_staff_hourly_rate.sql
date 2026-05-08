-- ============================================================================
-- 20260508000004 — Add hourly_rate_pence to staff_members
-- ----------------------------------------------------------------------------
-- Foundational column for R7 (staff time tracking / timesheets). Nullable
-- because not every kennel will track hourly rates — some salaried, some
-- volunteer, some informal. When NULL, the timesheets UI shows hours only
-- (no wage calculation).
--
-- Stored in pence to match the *_pence convention used in the pricing layer.
-- £12.50/hour = 1250 pence.
--
-- The column is additive — no downstream impact on existing reads/writes
-- of staff_members. RLS policies already cover update access for
-- kennel_owner role, so no new policy needed.
-- ============================================================================

alter table public.staff_members
  add column hourly_rate_pence int check (hourly_rate_pence is null or hourly_rate_pence >= 0);

comment on column public.staff_members.hourly_rate_pence is
  'Hourly pay rate in pence. NULL = rate not set (timesheet shows hours only). Used by R7 timesheets to compute wages from shift.started/shift.ended audit events.';

-- ============================================================================
-- 20260508000001 — Add run_count + cattery_count to tenants
-- ----------------------------------------------------------------------------
-- Foundational change for the pricing-and-plans layer. Plan capacity is
-- enforced against the total number of pens/runs a tenant has configured.
--
-- Operational data (the actual kennel rows) lives in Yjs/IndexedDB on the
-- client and is snapshotted to public.yjs_snapshots as opaque CRDT blobs —
-- not directly queryable server-side. Rather than parse Yjs server-side
-- (slow, fragile) or build a parallel server-side `kennels` table (refactor
-- of the existing architecture), we denormalise the count onto `tenants`.
--
-- The SPA is responsible for keeping these counters in sync whenever the
-- user adds or removes kennels/cattery suites. That is a follow-up SPA
-- change (out of scope for this migration). Until that lands, existing
-- tenants will have run_count=0 and the capacity-check helper will report
-- them as fully within limits — that is the safe default.
-- ============================================================================

alter table public.tenants
  add column run_count     int not null default 0 check (run_count     >= 0),
  add column cattery_count int not null default 0 check (cattery_count >= 0);

comment on column public.tenants.run_count     is
  'Configured kennel/run pens for this tenant. Denormalised counter, kept in sync by the SPA when kennels are added/removed. Used for SaaS plan capacity enforcement (see pq_check_plan_capacity).';
comment on column public.tenants.cattery_count is
  'Configured cattery suites for this tenant. Counts toward the same plan capacity limit as run_count.';

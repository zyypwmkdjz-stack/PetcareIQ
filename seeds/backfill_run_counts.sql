-- ============================================================================
-- backfill_run_counts.sql — one-shot for existing tenants
-- ----------------------------------------------------------------------------
-- Reads any `tenant.setup_completed` audit row(s) per tenant, extracts
-- kennelCount / catteryCount from details, and writes them to
-- tenants.run_count / cattery_count.
--
-- Idempotent: only backfills tenants where BOTH counters are still 0.
-- Tenants that have already had counts written are left alone.
--
-- Uses GROUP BY + MAX rather than `distinct on (tenant_id) order by ts` so
-- the script does not depend on the audit_log having a created_at-style
-- timestamp column. If a tenant has multiple setup_completed rows
-- (shouldn't happen normally), we take the largest count — defensive and
-- reasonable.
-- ============================================================================

with latest_setup as (
  select
    tenant_id,
    max(coalesce((details ->> 'kennelCount')::int,  0))  as kennel_count,
    max(coalesce((details ->> 'catteryCount')::int, 0))  as cattery_count
  from public.audit_log
  where action = 'tenant.setup_completed'
    and tenant_id is not null
  group by tenant_id
)
update public.tenants t
set
  run_count     = ls.kennel_count,
  cattery_count = ls.cattery_count,
  updated_at    = now()
from latest_setup ls
where t.id = ls.tenant_id
  and t.run_count     = 0
  and t.cattery_count = 0
returning
  t.id            as tenant_id,
  t.slug          as slug,
  t.name          as name,
  t.run_count     as run_count_after,
  t.cattery_count as cattery_count_after;

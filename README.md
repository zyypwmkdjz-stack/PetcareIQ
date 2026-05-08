# R7b — Manual shift override modal

Closes the loop on R7. When a carer's `shift.started` has no matching
`shift.ended`, the timesheet now shows a clickable "⚠ no end — fix" badge.
Clicking opens a modal where the owner enters the actual end time and an
optional reason, then saves.

## What gets written to `audit_log`

Two rows, inserted atomically via `supa.from('audit_log').insert([row1, row2])`:

1. **Synthetic `shift.ended`** with:
   - `occurred_at` = the entered end time (NOT now())
   - `actor_staff_id` = the carer being adjusted
   - `actor_user_id` = the owner doing the override
   - `actor_label` = the carer's name
   - `details` = `{ staff_id, adjusted: true, adjusted_by_user_id, original_started_at, reason }`

2. **`shift.adjusted` annotation** with:
   - `occurred_at` = now()
   - `actor_staff_id` = null (owner action, not a staff action)
   - `actor_user_id` = the owner doing the override
   - `actor_label` = "Owner override"
   - `details` = `{ adjusted_staff_id, adjusted_staff_name, original_started_at, applied_end_at, reason }`

The synthetic `shift.ended` makes the pairing logic in `_pairShifts()` see a
complete pair on the next render — no changes needed to the pairing logic.

The `shift.adjusted` row is the audit trail for the owner intervention.
Anyone reviewing the audit log later can see exactly when, why, and by whom
the original orphan was fixed.

## Validation in the modal

- End time must be set
- End time must be > start time
- End time must be ≤ now (cannot be in the future)
- All errors shown inline in red banner inside the modal

## RLS

No new policies needed. The existing `audit_log_tenant_insert` policy
allows `kennel_owner` and `kennel_staff` roles to insert into their own
tenant. We bypass `_writeAudit` (the Edge Function) because we need
explicit control over `occurred_at` and `actor_staff_id` for the synthetic
row.

## How to deploy

Drop-in replacement of `index.html` only. No SQL migration. No new
permissions. Hard refresh after deploy.

## Out of scope (R7c — future)

- Editing already-complete shifts (changing start time, end time on a
  shift that paired correctly). Adds audit-trail complexity around what
  the "original" values were.
- Voiding a clock-in entirely (carer accidentally tapped Switch to Carer).
- Fixing "⚠ no start" orphan-end case. Very rare; would need a different
  shape of modal (enter the actual start time).

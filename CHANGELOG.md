# PetcareIQ Baseline — 2026-05-06

**File:** `index.html` (18,891 lines · 1,081 KB)
**Validates:** ✅ `node --check` clean

## What's in this baseline (Phase B complete)

### Auth core
- `create_kennel_tenant` RPC migration (Supabase)
- Email + password auth (signup with kennel-creation, signin, password recovery)
- JWT app_role claims via `custom_access_token_hook`
- `body.pq-auth-pending` SPA gating
- Warm-signin wizard fire via `_maybeFireWizardForCurrentTenant()`
- Tenant ID via `_currentTenantId()` (no hardcoded constants)

### Multi-tenant correctness
- Full string sweep: 30+ "Meadow View Kennels"/"Gloucestershire" replaced with helpers
- 7 helpers: `_bizName`, `_bizAddressLong`, `_bizCity`, `_bizPhone`, `_bizEmail`, `_bizContactLine`, `_bizHeaderSub`
- BIZ extended with `phone` and `emailFrom` fields
- All booking emails, invoices, monthly reports, statements, CSV exports use helpers

### Setup wizard (7 steps)
- Welcome → Business → Cattery → Day rates → Vaccinations (cat section gated) → Confirm
- Manual sites INSERT to settle RLS race-timing

### Staff PIN flow (Pattern B — carer-mode overlay)
- Two Edge Functions deployed: `create-staff-member`, `validate-staff-pin`
- PBKDF2-SHA256 PIN hashing (100k iterations, format `pbkdf2$<iters>$<salt>$<hash>`)
- Tenant_id derived from caller JWT (not request body) — prevents cross-tenant probing
- `window.PETCAREIQ.activeCarer` — in-memory carer state, no session swap
- Settings → Staff & PINs editor (add/deactivate/reactivate)
- Carer entry modal: staff picker → PIN pad → activation
- Topbar carer pill with "End shift" button
- `body.carer-active` gates owner-only surfaces:
  - Sidebar nav items (Pet Owners, Billing, Settings)
  - Sidebar bottom user chip (Ian / Kennel Manager)
  - Dashboard Quick Actions (Invoices, Settings)
- Auto-redirect to Dashboard on carer activation/end-shift

### Audit trail (full coverage)
- `_writeAudit` stamps `actor_staff_id` from active carer state (51 callsites)
- Shift events: `shift.started`, `shift.ended`
- Staff CRUD: `staff.added`, `staff.deactivated`, `staff.reactivated`
- Daily care:
  - `feeding.completed` / `walk.completed` (kennel cards + dashboard schedule)
  - `medication.completed` (dashboard schedule)
  - `feeding.recorded` / `medication.recorded` (booking care log slots — transition-based)
- Dog detail Updates tab: `update.<type>` (note/walk/meal/meds/behaviour/incident)
- Dog detail Care Logs tab: `walk.completed`, `care.appetite_set`, `care.toileting_set`, `care.flag_raised`
- Booking lifecycle, payments, owner CRUD, exports — all pre-existing

### Owner portal (preview only)
- Honest amber banner: "Owner Portal — Preview"
- "Preview as:" dropdown for kennel owner / carers (carers can verify shared updates)
- Graceful empty state for tenants without demo data ("📭 No portal preview available yet")

## Known foundations laid (not yet built)

- Audit log already captures `shift.started` / `shift.ended` per `actor_staff_id` — direct foundation for **R7 timesheets**
- `app_role='pet_owner'` JWT claim already mapped to legacy `currentRole='owner'` — foundation for **R6b customer auth**
- All `_writeAudit` calls include `entity_table` and `entity_id` for FK lookups in future reporting

## Queued follow-ups (not in baseline)

- **R6b** — Real customer auth: schema (`pet_owners.auth_user_id`), Edge Function `send-customer-magic-link`, JWT `pet_owner_id` claim
- **R6c** — Real portal queries scoped by JWT pet_owner_id (replace PORTAL_DATA hardcoded demo)
- **R6d** — Booking confirmation email magic-link integration
- **R7** — Staff time tracking (timesheets, hourly rates, payroll CSV)
- **R7b** — Lunch deduction, overtime, bank holiday multiplier

## Edge Functions deployed (Supabase)

- `create-staff-member` — kennel_owner only, PBKDF2 hash, returns staff_id
- `validate-staff-pin` — kennel_owner only, returns `{ok, staff_id, display_name}`
- `list-staff-for-pin-picker` — deployed, unused (SPA queries staff_members directly via RLS)
- `custom_access_token_hook` — adds tenant_id + app_role claims to JWT

## Deploy notes

- Replace `index.html` in https://github.com/zyypwmkdjz-stack/PetcareIQ
- GitHub Pages serves at https://zyypwmkdjz-stack.github.io/PetcareIQ/
- Hard refresh (Cmd+Option+R on Mac Safari) to bypass cache after deploy

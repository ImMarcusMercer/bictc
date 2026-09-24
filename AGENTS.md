# Project agent entry flow

## Start here

1. Read the user request and inspect the files and current changes it affects.
2. Read `docs/project-structure-and-flow.md` when the task touches product behavior, architecture, ownership, data contracts, authentication, security, accessibility, or delivery order. Do not load the whole document for a purely mechanical edit.
3. Identify the boundary before editing:
   - `app/` contains the Flutter client.
   - `supabase/` contains the complete backend.
   - `contracts/` defines the shared client/backend interface.
   - `docs/` records project-level decisions and flows.
4. Use only the skills and current official documentation relevant to the task. Do not load unrelated workflows.
5. Make the smallest complete change, run the relevant checks, and report the evidence.

## Project invariants

- Supabase is the complete application backend. Do not introduce a separate backend service without an approved architecture change.
- The product Flutter app belongs in `app/`. The root `.flutter/` directory is an SDK checkout: do not edit it or add it to version control.
- Postgres migrations are the schema and RLS source of truth. Do not treat generated or manually described schemas as authoritative.
- Keep Supabase access behind repository adapters in `app/lib/shared/repositories/`; UI code must not call Supabase directly.
- Never put secret or service-role keys in Flutter. Enforce authorization with explicit grants, RLS, Storage policies, and trusted Edge Functions.
- Treat AI photo analysis as labeled suggestions, never as accessibility certification or community verification.
- Accessibility is a product requirement: do not rely on color alone, preserve assistive-technology semantics, and handle loading, empty, error, and offline states.
- Accessibility needs remain on-device by default and are sent only when needed to calculate a result.

## Contract and ownership rules

- Changes crossing Flutter and Supabase start with `contracts/data-contract.md` and matching examples once those files exist.
- Keep contract changes small and update affected migrations, adapters, fixtures, and tests consistently.
- Flutter work must not silently change migrations. Supabase work must not silently change Flutter screens.
- Preserve the result vocabulary and evidence traceability defined in `docs/project-structure-and-flow.md`.

## Implementation and verification

- Follow existing patterns before adding abstractions or dependencies. Create target-layout folders only when working files need them.
- For framework or package behavior, verify the exact installed version against current official documentation.
- For Flutter changes, format code and run the narrowest relevant analysis and tests; expand to the full suite when shared behavior changes.
- For Supabase changes, test both allowed and denied access paths for anonymous and signed-in users when policies are affected.
- Do not hide unrelated failures. State what was run, what passed, and what remains unverified.
- If a change alters a project-level decision or flow, update `docs/project-structure-and-flow.md` in the same change. Do not duplicate that document here.

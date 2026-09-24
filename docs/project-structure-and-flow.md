# PWD Accessibility App: Structure and Development Flow

## Product goal

A Flutter app helps people with disabilities judge whether an establishment's **entrance, route, facilities, and actual service area** meet their selected accessibility needs. Community evidence drives the result. AI suggests possible findings from photos but does not certify accessibility or replace human verification. The project supports SDG 10 and SDG 11.

## Technology decision

**Supabase is the complete application backend.** Flutter uses `supabase_flutter` to access Supabase Auth, Postgres through the Data API, Storage, and Edge Functions. There is no separate `backend/` application or custom REST server. Postgres migrations are the source of truth for the schema and access policies. Edge Functions handle server-only work such as image analysis and any operation that needs a secret. A third-party AI model, if selected later, is called only from an Edge Function; its credentials never go into Flutter.

The Flutter client uses a publishable key and authorization is enforced with Row Level Security (RLS). Secret or service-role keys belong only in Supabase server-side secrets. Browsing can be public; submitting or reviewing reports requires Supabase Auth. Accessibility needs stay on the device by default and are sent only as inputs when calculating a result.

## Proposed repository layout

```text
/
├── app/                                # Flutter app; frontend developer owns
│   ├── lib/
│   │   ├── app/                         # Routing, theme, accessibility settings
│   │   ├── features/
│   │   │   ├── needs/                   # Select accessibility needs
│   │   │   ├── discovery/               # Places, full map, and shared search
│   │   │   ├── establishments/          # Profile and feature details
│   │   │   ├── assessment/              # Personalized result and evidence
│   │   │   └── reports/                 # Read, submit, confirm, flag, dispute
│   │   └── shared/
│   │       ├── models/                  # Dart models matching the data contract
│   │       ├── repositories/            # Interface, fixture, and Supabase adapters
│   │       └── widgets/                 # Reusable accessible UI
│   └── test/
├── supabase/                           # Supabase backend; backend developer owns
│   ├── config.toml                     # Local Supabase project configuration
│   ├── migrations/                    # Tables, views, functions, grants, RLS
│   ├── seed.sql                       # Sample establishments and reports
│   ├── functions/
│   │   ├── analyze-report-photo/       # AI suggestion after photo submission
│   │   └── _shared/                    # Shared function code, if needed
│   └── tests/                          # Database policy and rule tests
├── contracts/                          # Jointly reviewed Supabase interface
│   ├── data-contract.md                # Tables/views, RPC signatures, enum meanings
│   └── examples/                       # Sample rows and function responses
├── docs/
│   └── project-structure-and-flow.md
└── .github/workflows/                  # Later: separate Flutter/Supabase checks
```

This is a **target layout**; create folders as working files are added. The existing root `.flutter/` directory is a Flutter SDK checkout, not the app. Do not place product code there or add the SDK checkout to the app's Git history.

## App screens and user journey

| Section | User action | Information to show |
| --- | --- | --- |
| Splash / Startup | Open the app while required startup work completes | App identity, a calm non-numeric loading state, and an accessible retry state if startup fails; no sign-in or permission prompt |
| Needs | Select practical access requirements on first launch or reopen My Needs from More | Locally saved selected needs and a way to change them later; do not infer a diagnosis or require an account |
| Places / Map | Search and filter either a card list or a full map | The same city, status, and selected-needs context in both tabs; recommendation matches stay separate from evidence status, and Places works without location permission |
| Establishment | Open a place | Address, offered services, evidence summary, and last observation date |
| Accessibility Details | Inspect entrance, ramp, doors, pathways, elevators/stairs, toilets, parking/drop-off, waiting area, counters, and route to the service area | Feature status, measurements with units, photos, source, verification state, and unknowns |
| Assessment | Read a result for selected needs | Result, main barrier, limitations, missing evidence, and links to supporting reports |
| Community Reports | Read or contribute evidence | Submit a report/photo, confirm a report, flag outdated or incorrect data, or dispute it |

```text
First launch -> Splash/startup -> Select needs -> Places list or full Map -> Establishment -> Accessibility details
Later launch -> Splash/startup -> Restore local needs -> Places list or full Map
            -> Personalized assessment -> Community reports/actions
            -> New evidence refreshes details and assessment
```

Use clear text and icons alongside color for every status. Show loading, empty, error, and offline states for data-driven screens. Public browsing should not force sign-in; prompt for sign-in when a user begins a contribution.

## Supabase data model and ownership

The backend developer defines these proposed tables and read models in migrations. `auth.users` is managed by Supabase Auth; application tables reference its user ID rather than copying credentials.

| Data | Purpose | Primary access |
| --- | --- | --- |
| `establishments` | Name, service category, address, coordinates | Public read; restricted write |
| `establishment_services` | Services and where they are provided, including floor/area | Public read; restricted write |
| `accessibility_features` | Feature types and establishment/service-area links | Public read; restricted write |
| `reports` | User observation, feature, measurement, unit, description, observed date, contributor | Public read of visible reports; signed-in user creates own report |
| `report_photos` | Storage path and report link | Read only when report is visible; uploader creates own links |
| `report_actions` | Confirm, flag, or dispute, actor, reason, timestamp | Public aggregate/read as appropriate; signed-in user creates own action |
| `ai_suggestions` | Possible feature/barrier, model metadata, source photo, processing state | Read with source label; only trusted Edge Function writes |
| `establishment_evidence` view | A stable read shape joining features, reports, actions, and AI suggestions | Public read; no direct client write |

Use stable UUIDs, UTC timestamps, explicit measurement units, and a defined vocabulary for feature types and statuses. A report is an observation, not a final verdict. Keep **source** (`user_reported` or `ai_detected`) separate from **verification state** (`unverified`, `community_verified`, `disputed`, or `outdated`). AI output never becomes community verified merely because it was generated.

Protect each exposed table with RLS and explicit grants. The policy intent is: anyone can read public establishment information and visible reports; a signed-in contributor can create evidence in their own name; contributors cannot edit another person's evidence or set verification totals; only trusted server-side code can write AI suggestions or curated establishment data. Publish valid reports without requiring a central verifier; community actions can change their verification state, and abuse rules can hide harmful content. Limit repeat confirmations by the same account. The public evidence view must use `security_invoker = true` so underlying table RLS applies. Storage policies must likewise restrict uploads and reads. Keep report photos in a private bucket and expose them only through approved read rules or short-lived signed URLs. Do not place secret keys in the app.

## Personalized result

The backend developer owns one Postgres RPC, provisionally `get_accessibility_assessment(establishment_id, need_codes)`, returning the result, reasons, barrier IDs, and evidence IDs. Flutter calls it through the Supabase client. Define it as `SECURITY INVOKER` so it uses the caller's table permissions and RLS; validate the supplied need codes. The frontend renders the response; it does not independently invent a conflicting score.

The four results are **Accessible**, **Accessible with limitations**, **Significant barrier**, and **Insufficient information**. A confirmed barrier on a route required for a selected need can produce a significant barrier. Missing, stale, or disputed evidence remains visible as uncertainty; it must not silently count as accessible. If a required route is unknown and no confirmed barrier settles the question, return insufficient information. Show the specific route or service area behind the result.

## Submission, community, and AI flow

```text
Contributor signs in with Supabase Auth
  -> Uploads photo to protected Supabase Storage
  -> Creates report + photo reference in Postgres
  -> Edge Function analyzes the photo and stores labeled suggestions
  -> Other contributors confirm, flag, dispute, or submit newer evidence
  -> Postgres view/RPC derives current evidence and personal result
  -> Flutter refreshes the establishment details and assessment
```

After saving a report, Flutter invokes `analyze-report-photo` with its report ID. The function validates the caller and report/photo link, retrieves the image server-side, and stores a **suggestion**, not a compliance decision. It must handle repeated calls for the same report safely. If analysis fails or the app closes before invoking it, keep the human report and show AI processing as pending or unavailable; allow retry. The first version can refresh after a successful action; Realtime is optional once live updates provide a clear benefit.

Protect contributors and bystanders: warn before uploading public evidence, discourage photos of faces or private information, store only the location needed to identify the establishment, and provide a way to flag harmful photos. Do not store users' selected accessibility needs in a public table.

## Contract and parallel work

`supabase/migrations/` is the executable source of truth. `contracts/data-contract.md` and JSON examples explain the client-facing table/view fields and RPC/function inputs and outputs. Both developers review changes to that contract before either side relies on them.

The first contract should fix these names and shapes before parallel implementation:

| Read or call | Minimum agreed fields |
| --- | --- |
| Establishment list/profile | `id`, `name`, `address`, coordinates, services, `last_observed_at` |
| Evidence row | `id`, `establishment_id`, `feature_code`, observation/status, `source`, `verification_state`, `observed_at`, measurement and unit, photo references |
| Assessment RPC input | `establishment_id` UUID and a list of functional `need_codes` |
| Assessment RPC output | Result code (`accessible`, `accessible_with_limitations`, `significant_barrier`, `insufficient_information`), reasons, main barrier, unknown feature codes, and supporting evidence references |
| Report action | Report ID, action (`confirm`, `flag`, `dispute`), reason, actor, timestamp |
| AI function input/output | Report ID input; processing state and suggestion references output |

Define allowed feature/need codes and error responses in `contracts/data-contract.md`. The contract's examples let the frontend use fixtures while the Supabase developer builds the real view and RPC.

| Boundary | Frontend developer | Supabase developer |
| --- | --- | --- |
| Read data | Build screens against fixture-backed repository and agreed example rows | Create tables, public views, grants, and RLS policies matching examples |
| Personal result | Render agreed RPC response | Implement and test assessment RPC |
| Contributions | Build Auth prompt, report forms, upload and action UI | Define Auth flow, report/action policies, Storage bucket and upload rules |
| AI | Show clearly labeled suggestions and unavailable state | Build Edge Function, secret configuration, validation, and processing status |

The frontend developer keeps Supabase calls inside `app/lib/shared/repositories/`; screens consume a repository interface. The backend developer does not edit Flutter screens. The frontend developer does not change migrations. A schema change starts as a small contract PR with updated examples, then the Supabase migration and Flutter adapter can land in separate PRs. Keep contract edits short and give one person ownership of each contract PR.

Use branches such as `frontend/assessment-screen` and `supabase/assessment-rpc`. Merge small PRs frequently. CI should run Flutter analysis/tests separately from Supabase migration and database policy tests. Test RLS for both allowed and denied reads/writes, including anonymous and signed-in users. The Supabase CLI keeps migrations and seed data in version control so each developer can recreate the same local backend.

## Delivery order

1. **Shared foundation:** agree on need codes, feature types, result meanings, example rows, Auth requirement for contributions, and the first data contract. Initialize `app/` and `supabase/` independently.
2. **Read-only journey:** frontend builds needs, list/map, profile, details, and assessment from fixtures. Supabase developer builds establishments, services, evidence view, RLS, seed data, and assessment RPC.
3. **Connect:** replace the fixture repository with `supabase_flutter` calls. Verify a user can browse and get an evidence-linked personalized result without signing in.
4. **Community evidence:** add Auth, report/photo upload, confirmations, flags, disputes, and policy tests.
5. **AI assistance:** add Edge Function photo analysis, distinct AI labels, failure handling, and human review. Add Realtime only if the product needs immediate cross-device updates.

The first shared milestone is **select needs -> find a place -> inspect evidence -> see a traceable personal result** using real Supabase data.

## Supabase references

- [Flutter quickstart and `supabase_flutter`](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Local development and migrations](https://supabase.com/docs/guides/local-development/cli-workflows)
- [Postgres RLS](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Edge Function secrets](https://supabase.com/docs/guides/functions/secrets)

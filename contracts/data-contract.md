# Client/backend contract

## Connection foundation

Flutter 3.47.5 uses `supabase_flutter` 2.17.2. Configuration is supplied at build time through `--dart-define-from-file=.env` from `app/`.

| Variable | Required when connecting | Meaning |
| --- | --- | --- |
| `SUPABASE_URL` | Yes | Project base URL from Supabase Connect; HTTPS for hosted projects |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | Client-visible `sb_publishable_...` key from the same project |

See [client configuration example](examples/client-config.json). Example values are not working credentials. This initial integration accepts modern publishable keys only, not legacy JWT anon keys or server keys.

Both values empty means sample-data preview without a Supabase client. Supplying only one or a malformed value fails startup. Initialization restores the SDK's local session state but does not prove that the project is reachable or the key is valid. Future protected operations must validate the current session and handle expired sessions and network failures.

All data and Auth operations belong in adapters under `app/lib/shared/repositories/`. Widgets must not access the Supabase singleton. A publishable key is embedded in the built client; authorization depends on database grants, RLS, Storage policies, and validated server functions.

## More feature boundary

The planned flow and storage decisions live in [Phase 1](../docs/project-structure-and-flow.md#more-menu-and-supabase-flow). There are no implemented remote My Needs, Favorites, or Settings operations yet. Community contributions now connect the email/password login form through the reports repository; see the Community reports contract below.

Before implementing Favorites sync, add the exact table fields, establishment UUID references, uniqueness constraints, error behavior, and example rows here, followed by a migration with owner-only RLS and tests for two different users and anonymous access. Current map fixtures do not have persistent establishment IDs and must not be written as remote favorites.

`supabase/migrations/` will be the executable schema source of truth. `docs/scheme.sql` is a proposal workspace, not a deployed schema or migration history.

## Community reports

Guests (including Supabase anonymous sessions) can read visible reports and their photos. Any non-anonymous signed-in account may submit reports/photos and mark a report helpful; no additional verification or email-confirmation check is imposed by this module. Supabase Auth's own sign-in settings still apply. Account eligibility never implies community verification of evidence.

`docs/scheme.sql` proposes the following interface; it must be promoted to migrations and applied before using the live adapter:

- `reports`: UUID `id`, `author_id` referencing Auth, public `author_name` (1–80 characters), `place_name` (1–160), `city` (1–80), `description` (1–2000), `status` (`accessible`, `partial`, `barrier`), `observed_at` date, `created_at` UTC timestamp, `source` fixed to `user_reported`, `verification_state` default `unverified`, `is_visible` default true, optional `photo_path`. Place names are observations, not links to fixture establishment IDs; personalized assessments do not consume them yet.
- `report_helpful`: composite key `(report_id, user_id)`. Authenticated accounts can insert/delete their own vote on visible reports. Clients cannot edit aggregate counts, visibility, source, timestamps, or verification state.
- `community_report_feed(p_city text default null, p_status text default null, p_offset int default 0, p_limit int default 20)`: public read RPC returning visible report fields plus `helpful_count` and caller-specific `is_helpful`, newest first (timestamp and UUID). Offset is nonnegative; limit is 1–50. This narrowly scoped security-definer function exposes no voter identities or hidden reports.
- Report insert supplies only author/name/place/city/description/status/observed date. Photo attachment is a separate update to `photo_path`. One JPEG, PNG, or WebP up to 5 MiB is stored at `<user UUID>/<report UUID>/evidence` in private bucket `report-photos`. Only that report's signed-in owner can upload/link it. Public reads require a visible report with that exact attached path; URLs expire after 10 minutes.
- If attachment fails or its response is lost after insert, the text report remains published and the UI reports that attachment could not be confirmed, without retrying the insert. Uncertain uploads are retained because the photo link may already have committed; trusted server cleanup must remove only confirmed orphans. No offline writes are queued. Read failures keep any previously loaded data with a retry message. Preview mode is explicitly labeled sample data and rejects all writes.

Example: [community report](examples/community-report.json). Authentication and all Supabase operations remain behind the reports repository. Existing accounts sign in using email/password; registration, moderation tooling, AI analysis, and report verification workflows are outside this module.

## Favorites, catalog, and Settings contract

Guest favorites are device-local snapshots, keyed by a real establishment UUID when available or a namespaced sample key in preview. Signing in imports only real establishment IDs into that account with idempotent inserts. Local entries are removed only after a successful import for the same session; failures retain them for retry. Sample favorites never enter Supabase. Signing out clears account records from memory before showing guest data. No account favorites or credentials are persisted in the guest store.

`establishments` supplies the live catalog: `id` UUID, `name`, `category`, `city`, `area`, `address`, `latitude`, `longitude`, `access_status` (`accessible`, `partial`, `barrier`, `unknown`), `supported_need_codes` array, `report_count`, `last_observed_at`, and `is_visible`. Curated access tags are indications, not personalized assessments or certification. Anonymous users can read visible establishments; only trusted server code edits them. The Flutter adapter pages through the catalog. A failed live read never silently switches to samples.

`favorites` has composite primary key (`user_id`, `establishment_id`), Auth/establishment foreign keys, and a server timestamp `created_at`. Authenticated non-anonymous users can read, insert, and delete their own records, with insert limited to visible establishments. No client updates or cross-account reads. The adapter reads `establishments(*)` through the relationship; hidden establishments appear as unavailable favorites that can still be removed.

Settings shows session status, sign-in/sign-out, larger text, reduced motion, and app information. Preferences persist on-device in a versioned JSON value; toggles take effect app-wide after storage accepts the write. Device settings never write a public user profile. Larger text adds a minimum scale without reducing system text settings. Reduced motion honors system accessibility settings and removes app route transitions. My Needs continues to be on-device/session-local until its own persistence work; no needs are copied into the database.

The expanded SQL proposal also defines supporting evidence tables and locked-down voice-assistance records. These future modules have no client write access unless explicitly stated. Creating tables does not implement assessment calculation, AI analysis, voice authorization, realtime delivery, or LiveKit integration. See the setup guide for prerequisites and deployment order.

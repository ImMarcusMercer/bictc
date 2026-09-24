# Voice assistance: Supabase and LiveKit

Status: compatibility checked; proposed implementation design, 2026-09-24. This is now the product priority. No LiveKit integration is deployed by this review.

## Experience

A verified PWD or elderly user selects **Call**. Other users receive a simple, dismissible notification and can volunteer to help. Audio begins only after deliberate participation. Incoming requests use no full-screen call UI, repeated ringing, or automatic answering.

Suggested popup: **Voice assistance requested** / **Someone would like help. Can you talk?** with **Help** and **Dismiss**. Do not broadcast disability details, verification documents, phone numbers, precise location, room tokens, or audio. Use accessible labels, large controls, and text for connection states.

## Compatibility evidence

| Boundary | Finding | Evidence |
| --- | --- | --- |
| Flutter + LiveKit | Supports Android and web, the project's current targets | [LiveKit Flutter SDK](https://pub.dev/packages/livekit_client) |
| Dependencies | `flutter pub add --dry-run livekit_client:2.13.0` succeeded with Flutter 3.47.5 / Dart 3.13.4 and `supabase_flutter` 2.17.2; 21 additional dependencies would resolve | Local solver check; LiveKit was not added to the app |
| Edge Functions | LiveKit's JS server SDK supports Deno, the runtime used by Supabase Functions | [LiveKit server SDK](https://docs.livekit.io/reference/server-sdk-js/), [Supabase Functions](https://supabase.com/docs/guides/functions) |
| Foreground popups | Private Realtime channels support authorized event delivery | [Realtime authorization](https://supabase.com/docs/guides/realtime/authorization) |
| Background notifications | Functions can send push; the client needs platform push setup | [Supabase push](https://supabase.com/docs/guides/functions/examples/push-notifications), [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages) |

This establishes architectural and dependency compatibility, not an Android/web build with LiveKit, a deployed Deno integration, or a successful audio call. Those remain acceptance checks.

## Recommended arrangement

Use **Supabase + LiveKit Cloud**, with Realtime foreground events and FCM for Android background notifications. Supabase owns application data and authorization, LiveKit carries audio, and FCM delivers device notifications. No additional application backend is needed.

A foreground-only increment can validate the UX but cannot notify closed apps. Self-hosted LiveKit is another option, with additional server operation and different token-revocation behavior. Cloud is the proposed starting point; this review provisions no paid service.

## Request flow

1. Caller signs in through Supabase Auth. Server-controlled verification confirms current PWD/elderly eligibility. A client checkbox, My Needs selection, or editable user metadata cannot grant verification.
2. **Call** checks microphone permission and invokes an authenticated Edge Function. The function derives the user ID from the validated session, checks eligibility and rate limits, and atomically writes a request and notification-dispatch job. Enforce one active request per caller.
3. A dispatcher creates durable recipient inbox entries and sends Realtime events and configured push messages. Use minimal request ID/status/expiry payloads. Clients cannot publish authoritative request events.
4. Recipients see an in-app popup or an ordinary OS notification. **Help** opens the current request and checks availability. A notification never automatically joins a room.
5. Proposed first version: the first accepting responder claims the request atomically. Concurrent attempts get `already_claimed`. This one-to-one rule awaits confirmation.
6. The caller and selected responder each request a LiveKit token. The Edge Function rechecks membership and request state, then issues a short-lived room-scoped token with microphone publishing and subscription permission. Use opaque IDs, with no camera, administration, or recording grant. [LiveKit grants](https://docs.livekit.io/frontends/reference/tokens-grants/)
7. Flutter connects directly to LiveKit after consent. Show mute, audio route, connection state, and **End**. The proposed initial experience uses audio only, without recording.
8. End/cancel updates request state and schedules idempotent media cleanup. Recipients stop offering **Help**. Late notifications open a closed-request message.

Proposed lifecycle: `pending -> accepted -> active -> ended`; alternative terminal states are `cancelled`, `expired`, and `failed`. A join timeout handles a responder who never connects. Fix timing and reassignment rules in the contract before implementation. Network loss displays reconnecting rather than immediately treating it as a deliberate hang-up.

Signed LiveKit webhooks reconcile room/participant state. Verify the raw body signature and deduplicate event IDs. Delivery is retried but not guaranteed, so add expiry/reconciliation jobs. [LiveKit webhooks](https://docs.livekit.io/intro/basics/rooms-participants-tracks/webhooks-events/)

Token expiry does not end a connected session. Terminal requests deny new tokens and perform media cleanup. On LiveKit Cloud, explicitly revoke participant tokens when ending access and test strict revocation cutoffs and cached-token rejoins. Self-hosted removal does not invalidate issued tokens and requires a separately validated strategy. [Token lifecycle](https://docs.livekit.io/frontends/reference/tokens-grants/)

## Notify all users

Working interpretation: all registered active users except the caller are recipients, without geographic filtering. Receiving a notice does not grant room access. Whether responders also require verification is an open decision; the initial proposal allows ordinary signed-in users to help.

Store notifications durably and dispatch in batches with retries and per-request/per-recipient uniqueness. On app resume or reconnect, fetch current inbox and request state. Deduplicate Realtime and push events. Stop pending dispatch when a request closes; recheck state when opening a delayed notice.

Delivery cannot be guaranteed to every device: permission, connectivity, channel settings, and force-stop state affect receipt. Keep an in-app inbox for missed requests. [FCM handling](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)

In-app popups use the app's own style. OS banners depend on channel importance and user settings; silent low-importance notifications may appear only in the tray. Use an ordinary help-request channel without full-screen/call-style presentation and test banner behavior on the target phone. Transport priority and visual style are separate settings. [Android channels](https://developer.android.com/develop/ui/compose/notifications/channels)

## Proposed backend records

These are candidates, not deployed schema. Finalize exact fields, example payloads, grants, and migrations before client integration.

| Record | Responsibility/access |
| --- | --- |
| `user_verifications` | Eligibility/category/status and reviewer audit; trusted workflow writes, subject and authorized reviewer read |
| `assistance_requests` | Caller, responder, lifecycle, expiry, room reference; server-controlled transitions; full record restricted to participants and authorized operations |
| `user_notifications` | Minimal request notice per recipient; owner reads/marks their notices; server creates |
| `device_push_tokens` | Owner registers devices; dispatcher reads tokens; no cross-user access |
| `notification_outbox` | Durable dispatch, retries, deduplication; server-only |
| `livekit_events` | Processed webhook IDs and reconciliation metadata; server-only |

Candidate functions: `create-assistance-request`, `accept-assistance-request`, `livekit-token`, `end-assistance-request`, `dispatch-assistance-notifications`, and `livekit-webhook`. Private database routines enforce atomic transitions. User endpoints validate Supabase sessions; the webhook validates LiveKit signatures instead of requiring a Supabase user token.

RLS/grants must deny self-verification, forged identities, arbitrary lifecycle edits, cross-user inbox/device reads, and unauthorized room joins. Realtime exposes minimal notices instead of full request records, with receive-only client access. Flutter calls go through repository adapters; widgets never call Supabase directly.

## Credentials

| Location | Values |
| --- | --- |
| `app/.env` | Existing `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`; the authorized endpoint returns the LiveKit URL and join token |
| Edge Function secrets | `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`, plus push-provider server credentials when implemented |
| Push client setup | Platform-specific Firebase client config; web additionally needs a service worker and browser configuration |

LiveKit secrets, push private keys, and Supabase server keys must never enter Flutter. Room tokens stay out of notification payloads, logs, and database rows. No LiveKit/push credentials were configured in this review.

## Open decisions and acceptance checks

- Verification authority: admin approval, external verification, or another trusted process. Unverified users cannot self-enable Call.
- Response model: recommended first responder for one-to-one audio; alternatives are caller selection or a group room.
- Audience: confirm registered active users and whether every signed-in recipient can help.
- Define expiry, join timeout, notification preferences, and whether audio must continue when backgrounded.

Start with Auth, the verification contract, and request-state/RLS tests. Follow with a two-client foreground voice test and background push. Test unverified/anonymous callers, simultaneous responders, cross-user access, denied permissions, disconnections, expiry, duplicate events, cached tokens after ending, and missed-push recovery. Background audio needs explicit platform configuration and testing; push handlers must not start microphones.

-- Proposed project database structure for Supabase PostgreSQL.
-- Implemented adapters: catalog, favorites, community reports, and Auth.
-- Supporting evidence/voice tables below are proposals, not deployed services.
-- Settings and guest favorites are device-local; no public needs/profile table.
-- Proposal only: promote to reviewed supabase/migrations before deployment.
-- Run once against a clean Supabase database; existing installations need migrations.
-- No extra account verification: any non-anonymous signed-in account may contribute.
begin;

-- Catalog and account favorites. Seed only real, curated establishment records.
create table public.establishments (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 160),
  category text not null check (char_length(btrim(category)) between 1 and 80),
  city text not null check (char_length(btrim(city)) between 1 and 80),
  area text not null default '',
  address text not null check (char_length(btrim(address)) between 1 and 500),
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  access_status text not null default 'unknown' check (access_status in ('accessible','partial','barrier','unknown')),
  supported_need_codes text[] not null default '{}' check (supported_need_codes <@ array['wheelchair','visual','hearing','walker','senior','cognitive','sensory','chronic']::text[]),
  report_count integer not null default 0 check (report_count >= 0),
  last_observed_at date,
  is_visible boolean not null default true,
  created_at timestamptz not null default now()
);
comment on column public.establishments.access_status is 'Curated browse label, not the personalized assessment result. Unknown until supported by reviewed evidence.';
comment on column public.establishments.supported_need_codes is 'Curated matching tags. This is not a record of any person''s selected needs.';
comment on column public.establishments.report_count is 'Trusted maintained summary; no automatic counter or assessment pipeline is implemented yet.';
create index establishments_city_idx on public.establishments(city, name) where is_visible;
alter table public.establishments enable row level security;
revoke all on public.establishments from public, anon, authenticated;
grant select on public.establishments to anon, authenticated;
create policy establishments_visible_read on public.establishments for select to anon, authenticated using (is_visible);

create table public.favorites (
  user_id uuid not null references auth.users(id) on delete cascade,
  establishment_id uuid not null references public.establishments(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, establishment_id)
);
create index favorites_establishment_idx on public.favorites(establishment_id);
alter table public.favorites enable row level security;
revoke all on public.favorites from public, anon, authenticated;
grant select, delete on public.favorites to authenticated;
grant insert(user_id, establishment_id) on public.favorites to authenticated;
create policy favorites_own_read on public.favorites for select to authenticated
  using (user_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));
create policy favorites_own_insert on public.favorites for insert to authenticated
  with check (user_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false)
    and exists (select 1 from public.establishments e where e.id = establishment_id and e.is_visible));
create policy favorites_own_delete on public.favorites for delete to authenticated
  using (user_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));

-- Supporting evidence foundations (proposed; only catalog/favorites are wired in Flutter).
create table public.establishment_services (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 160),
  floor_label text, service_area text,
  unique(id, establishment_id)
);
create table public.accessibility_features (
  id uuid primary key default gen_random_uuid(),
  establishment_id uuid not null references public.establishments(id) on delete cascade,
  service_id uuid,
  feature_code text not null check (feature_code in ('entrance','ramp','door','pathway','elevator','stairs','toilet','parking','drop_off','waiting_area','counter','service_route')),
  description text not null default '',
  foreign key(service_id, establishment_id) references public.establishment_services(id, establishment_id) on delete cascade,
  unique(id, establishment_id)
);
create index establishment_services_parent_idx on public.establishment_services(establishment_id);
create index accessibility_features_parent_idx on public.accessibility_features(establishment_id);
alter table public.establishment_services enable row level security;
alter table public.accessibility_features enable row level security;
revoke all on public.establishment_services, public.accessibility_features from public, anon, authenticated;
grant select on public.establishment_services, public.accessibility_features to anon, authenticated;
create policy services_visible_read on public.establishment_services for select to anon, authenticated
  using (exists(select 1 from public.establishments e where e.id = establishment_id and e.is_visible));
create policy features_visible_read on public.accessibility_features for select to anon, authenticated
  using (exists(select 1 from public.establishments e where e.id = establishment_id and e.is_visible));

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references auth.users(id) on delete cascade,
  establishment_id uuid references public.establishments(id),
  feature_id uuid,
  measurement numeric check (measurement >= 0),
  measurement_unit text check (measurement_unit in ('mm','cm','m','degrees','percent')),
  check ((measurement is null) = (measurement_unit is null)),
  check (feature_id is null or establishment_id is not null),
  foreign key(feature_id, establishment_id) references public.accessibility_features(id, establishment_id),
  author_name text not null check (char_length(btrim(author_name)) between 1 and 80),
  place_name text not null check (char_length(btrim(place_name)) between 1 and 160),
  city text not null check (char_length(btrim(city)) between 1 and 80),
  description text not null check (char_length(btrim(description)) between 1 and 2000),
  status text not null check (status in ('accessible', 'partial', 'barrier')),
  observed_at date not null check (observed_at between date '2000-01-01' and (current_date + 1)),
  created_at timestamptz not null default now(),
  source text not null default 'user_reported' check (source = 'user_reported'),
  verification_state text not null default 'unverified'
    check (verification_state in ('unverified', 'community_verified', 'disputed', 'outdated')),
  is_visible boolean not null default true,
  unique(id, photo_path),
  photo_path text check (photo_path = author_id::text || '/' || id::text || '/evidence')
);
comment on column public.reports.status is 'Contributor observation, not a personalized assessment or certification.';
comment on column public.reports.place_name is 'Free-text observed establishment; never treat map fixture IDs as persistent establishment IDs.';
comment on column public.reports.observed_at is 'Local observation date; one day UTC tolerance for client time zones.';
create index reports_feed_idx on public.reports (created_at desc, id desc) where is_visible;
create index reports_city_status_idx on public.reports (city, status, created_at desc) where is_visible;
create index reports_author_idx on public.reports (author_id);

create table public.report_helpful (
  report_id uuid not null references public.reports(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (report_id, user_id)
);
create index report_helpful_user_idx on public.report_helpful (user_id);

alter table public.reports enable row level security;
alter table public.report_helpful enable row level security;
revoke all on public.reports, public.report_helpful from public, anon, authenticated;
grant select on public.reports to anon, authenticated;
grant insert (author_id, author_name, place_name, city, description, status, observed_at, establishment_id, feature_id, measurement, measurement_unit)
  on public.reports to authenticated;
grant update (photo_path) on public.reports to authenticated;
grant select, delete on public.report_helpful to authenticated;
grant insert (report_id, user_id) on public.report_helpful to authenticated;

create policy reports_public_read on public.reports for select to anon, authenticated
  using (is_visible);
create policy reports_account_insert on public.reports for insert to authenticated
  with check (author_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false)
    and (establishment_id is null or exists(select 1 from public.establishments e where e.id = establishment_id and e.is_visible)));
create policy reports_owner_photo_update on public.reports for update to authenticated
  using (is_visible and author_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false))
  with check (is_visible and author_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));
create policy helpful_own_read on public.report_helpful for select to authenticated
  using (user_id = (select auth.uid()));
create policy helpful_own_insert on public.report_helpful for insert to authenticated
  with check (user_id = (select auth.uid())
    and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false)
    and exists (select 1 from public.reports r where r.id = report_id and r.is_visible));
create policy helpful_own_delete on public.report_helpful for delete to authenticated
  using (user_id = (select auth.uid()) and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));

-- Narrow public projection. Definer access is needed only to aggregate private votes.
-- Hidden reports are always excluded; voter identities never leave this function.
-- No dynamic SQL; all relations are qualified and search_path is empty.
create function public.community_report_feed(
  p_city text default null, p_status text default null,
  p_offset integer default 0, p_limit integer default 20
) returns table (
  id uuid, author_id uuid, author_name text, place_name text, city text,
  description text, status text, observed_at date, created_at timestamptz,
  source text, verification_state text, photo_path text,
  helpful_count bigint, is_helpful boolean
) language plpgsql stable security definer set search_path = '' as $$
begin
  if p_offset is null or p_offset < 0 or p_limit is null or p_limit not between 1 and 50
    or (p_status is not null and p_status not in ('accessible', 'partial', 'barrier')) then
    raise exception 'Invalid feed parameters' using errcode = '22023';
  end if;
  return query
    select r.id, r.author_id, r.author_name, r.place_name, r.city, r.description,
      r.status, r.observed_at, r.created_at, r.source, r.verification_state, r.photo_path,
      (select count(*) from public.report_helpful h where h.report_id = r.id),
      exists (select 1 from public.report_helpful h where h.report_id = r.id and h.user_id = auth.uid())
    from public.reports r
    where r.is_visible and (p_city is null or r.city = p_city) and (p_status is null or r.status = p_status)
    order by r.created_at desc, r.id desc limit p_limit offset p_offset;
end;
$$;
revoke all on function public.community_report_feed(text, text, integer, integer) from public;
grant execute on function public.community_report_feed(text, text, integer, integer) to anon, authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('report-photos', 'report-photos', false, 5242880, array['image/jpeg', 'image/png', 'image/webp']);
-- Storage API supplies object metadata and enforces the bucket size/MIME limits.
-- No update policy: uploads cannot overwrite an existing object.
create policy report_photos_owner_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'report-photos'
    and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false)
    and exists (select 1 from public.reports r
      where r.author_id = (select auth.uid()) and r.is_visible
        and name = r.author_id::text || '/' || r.id::text || '/evidence'));
create policy report_photos_visible_read on storage.objects for select to anon, authenticated
  using (bucket_id = 'report-photos' and exists (
    select 1 from public.reports r where r.is_visible and r.photo_path = name));
-- Owners can also read unattached objects so failed attachments can be cleaned up.
create policy report_photos_owner_read on storage.objects for select to authenticated
  using (bucket_id = 'report-photos' and owner_id = (select auth.uid())::text
    and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));
create policy report_photos_owner_cleanup on storage.objects for delete to authenticated
  using (bucket_id = 'report-photos' and owner_id = (select auth.uid())::text
    and not coalesce((select auth.jwt()->>'is_anonymous')::boolean, false));

-- Moderation, verification, and account-deletion orphan cleanup belong to trusted
-- server code. Signed URLs remain usable until expiry (the app requests 600s).
-- AI suggestions, assessment integration, and establishment foreign keys are future
-- migrations, not inferred from the unverified free-text reports in this module.

-- A single-photo read model preserves the current report/photo client contract.
create view public.report_photos with (security_invoker = true) as
  select id as report_id, author_id as uploader_id, photo_path as storage_path, created_at
  from public.reports where photo_path is not null;
revoke all on public.report_photos from public, anon, authenticated;
grant select on public.report_photos to anon, authenticated;

create table public.report_actions (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references public.reports(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('confirm','flag','dispute')),
  reason text check (char_length(reason) <= 2000),
  check (action = 'confirm' or char_length(btrim(reason)) > 0 and reason is not null),
  created_at timestamptz not null default now(),
  unique(report_id, actor_id, action)
);
alter table public.report_actions enable row level security;
revoke all on public.report_actions from public, anon, authenticated;
grant select on public.report_actions to authenticated;
-- Submission/moderation APIs are future work: no client action-write grant yet.
create policy report_actions_owner_read on public.report_actions for select to authenticated
  using (actor_id = (select auth.uid()));

create table public.ai_suggestions (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null,
  photo_path text not null,
  foreign key(report_id, photo_path) references public.reports(id, photo_path) on delete cascade,
  source text not null default 'ai_detected' check (source = 'ai_detected'),
  verification_state text not null default 'unverified' check (verification_state = 'unverified'),
  processing_state text not null default 'pending' check (processing_state in ('pending','processing','complete','failed')),
  model_name text,
  model_version text,
  suggestion text,
  confidence numeric check (confidence between 0 and 1),
  created_at timestamptz not null default now(),
  unique(report_id, photo_path, model_name, model_version)
);
alter table public.ai_suggestions enable row level security;
revoke all on public.ai_suggestions from public, anon, authenticated;
grant select on public.ai_suggestions to anon, authenticated;
create policy ai_visible_read on public.ai_suggestions for select to anon, authenticated
  using (exists(select 1 from public.reports r where r.id = report_id and r.is_visible));
create view public.establishment_evidence with (security_invoker = true) as
  select r.id as report_id, r.establishment_id, r.feature_id, f.feature_code,
    f.service_id, r.status as observation_status, r.description, r.measurement,
    r.measurement_unit, r.source, r.verification_state, r.observed_at, r.photo_path
  from public.reports r
  join public.establishments e on e.id = r.establishment_id
  left join public.accessibility_features f on f.id = r.feature_id;
revoke all on public.establishment_evidence from public, anon, authenticated;
grant select on public.establishment_evidence to anon, authenticated;
-- No assessment RPC is stubbed: returning invented results would imply evidence
-- processing that does not exist. Implement/test it in a separate migration.

-- Voice-assistance foundation: proposed only; trusted Edge Functions own writes.
-- No verification is inferred from account sign-in or device accessibility needs.
create table public.user_verifications (
  user_id uuid primary key references auth.users(id) on delete cascade,
  category text not null check (category in ('pwd','elderly')),
  status text not null default 'pending' check (status in ('pending','approved','rejected','revoked')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  check (status <> 'approved' or reviewed_at is not null)
);
create table public.assistance_requests (
  id uuid primary key default gen_random_uuid(),
  caller_id uuid not null references auth.users(id) on delete cascade,
  responder_id uuid references auth.users(id),
  status text not null default 'pending' check (status in ('pending','accepted','active','ended','cancelled','expired','failed')),
  room_name text unique,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  accepted_at timestamptz,
  ended_at timestamptz,
  check (expires_at > created_at),
  check (responder_id is null or responder_id <> caller_id),
  check (status not in ('accepted','active') or responder_id is not null),
  check ((status in ('ended','cancelled','expired','failed')) = (ended_at is not null))
);
create unique index assistance_one_active_caller on public.assistance_requests(caller_id)
  where status in ('pending','accepted','active');
create index assistance_responder_idx on public.assistance_requests(responder_id);
create table public.user_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null references public.assistance_requests(id) on delete cascade,
  kind text not null check (kind in ('assistance_requested','assistance_closed')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  read_at timestamptz,
  unique(recipient_id, request_id, kind)
);
create table public.device_push_tokens (
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id uuid not null,
  platform text not null check (platform in ('android','web','ios')),
  push_token text not null check (char_length(push_token) between 1 and 4096),
  enabled boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key(user_id, device_id)
);
create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.assistance_requests(id) on delete cascade,
  event_kind text not null check (event_kind in ('requested','closed','cleanup_room')),
  state text not null default 'pending' check (state in ('pending','processing','complete','failed')),
  attempts integer not null default 0 check (attempts >= 0),
  available_at timestamptz not null default now(),
  locked_at timestamptz,
  created_at timestamptz not null default now(),
  unique(request_id, event_kind)
);
create table public.livekit_events (
  event_id text primary key,
  event_type text not null,
  request_id uuid references public.assistance_requests(id) on delete set null,
  received_at timestamptz not null default now(),
  processed_at timestamptz
);
-- Never store LiveKit join tokens, API secrets, raw audio, or private documents here.
alter table public.user_verifications enable row level security;
alter table public.assistance_requests enable row level security;
alter table public.user_notifications enable row level security;
alter table public.device_push_tokens enable row level security;
alter table public.notification_outbox enable row level security;
alter table public.livekit_events enable row level security;
revoke all on public.user_verifications, public.assistance_requests, public.user_notifications,
  public.device_push_tokens, public.notification_outbox, public.livekit_events from public, anon, authenticated;
grant select on public.user_verifications, public.assistance_requests,
  public.user_notifications, public.device_push_tokens to authenticated;
grant update(read_at) on public.user_notifications to authenticated;
create policy verification_subject_read on public.user_verifications for select to authenticated
  using (user_id = (select auth.uid()));
create policy assistance_participant_read on public.assistance_requests for select to authenticated
  using (caller_id = (select auth.uid()) or responder_id = (select auth.uid()));
create policy notification_recipient_read on public.user_notifications for select to authenticated
  using (recipient_id = (select auth.uid()));
create policy notification_recipient_update on public.user_notifications for update to authenticated
  using (recipient_id = (select auth.uid())) with check (recipient_id = (select auth.uid()));
create policy push_token_owner_read on public.device_push_tokens for select to authenticated
  using (user_id = (select auth.uid()));
-- Push registration, dispatch, expiry, participant claims, and webhooks need trusted
-- functions with session/signature checks and transaction-safe transitions first.
-- No realtime publication or broadcast-write policies are enabled by this proposal.

grant all on public.establishments, public.favorites, public.establishment_services,
  public.accessibility_features, public.reports, public.report_helpful, public.report_actions,
  public.ai_suggestions, public.user_verifications, public.assistance_requests,
  public.user_notifications, public.device_push_tokens, public.notification_outbox,
  public.livekit_events to service_role;
grant select on public.report_photos, public.establishment_evidence to service_role;
grant execute on function public.community_report_feed(text,text,integer,integer) to service_role;
commit;

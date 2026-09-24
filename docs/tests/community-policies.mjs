// Usage: node docs/tests/community-policies.mjs <directory containing node_modules>
// Runs the proposal against PostgreSQL in PGlite, with minimal Supabase platform stubs.
// Does not exercise Supabase HTTP/Storage services or deploy anything.
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';
const require = createRequire(resolve(process.argv[2], 'package.json'));
const { PGlite } = require('@electric-sql/pglite');
const db = new PGlite();
await db.exec(`
  create role anon nologin;
  create role authenticated nologin;
  create role service_role nologin bypassrls;
  create schema auth;
  create schema storage;
  create table auth.users(id uuid primary key);
  create function auth.jwt() returns jsonb language sql stable as
    'select coalesce(nullif(current_setting(''request.jwt.claims'', true), ''''), ''{}'')::jsonb';
  create function auth.uid() returns uuid language sql stable as
    'select (auth.jwt()->>''sub'')::uuid';
  grant usage on schema auth, storage, public to anon, authenticated;
  grant execute on all functions in schema auth to anon, authenticated;
  create table storage.buckets(id text primary key, name text, public boolean, file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects(id uuid default gen_random_uuid(), bucket_id text references storage.buckets(id), name text, owner_id text);
  alter table storage.objects enable row level security;
  grant select, insert, update, delete on storage.objects to anon, authenticated;
`);
await db.exec(readFileSync(new URL('../scheme.sql', import.meta.url), 'utf8').replace(/^\uFEFF/, ''));
const a = '10000000-0000-4000-8000-000000000001';
const b = '10000000-0000-4000-8000-000000000002';
await db.exec(`insert into auth.users values ('${a}'), ('${b}')`);
let checks = 0;
async function role(name, user, anonymous = false) {
  await db.exec('reset role');
  await db.query("select set_config('request.jwt.claims', $1, false)", [JSON.stringify(user ? { sub: user, is_anonymous: anonymous } : {})]);
  await db.exec(`set role ${name}`);
}
async function denied(sql, args = []) {
  await assert.rejects(db.query(sql, args), error => ['42501', '23505', '23514', '22023'].includes(error.code));
  checks++;
}
async function count(sql, expected, args = []) {
  const { rows } = await db.query(sql, args);
  assert.equal(rows.length, expected, sql);
  checks++;
}
const insert = `insert into public.reports(author_id,author_name,place_name,city,description,status,observed_at)
 values ($1,'Tester','Hall','Cebu','Ramp clear','accessible',current_date) returning id`;
await role('anon');
await count('select * from public.community_report_feed()', 0);
await denied(insert, [a]);
await role('authenticated', a, true);
await denied(insert, [a]);
await role('authenticated', a);
await denied(insert, [b]);
const { rows: [report] } = await db.query(insert, [a]); checks++;
const id = report.id;
const path = `${a}/${id}/evidence`;
await denied(`update public.reports set verification_state='community_verified' where id=$1`, [id]);
await denied(`update public.reports set is_visible=false where id=$1`, [id]);
await denied(`update public.reports set photo_path='someone/else/photo' where id=$1`, [id]);
await db.query(`insert into storage.objects(bucket_id,name,owner_id) values ('report-photos',$1,$2)`, [path,a]); checks++;
await count('select * from storage.objects', 1);
await role('anon');
await count('select * from storage.objects', 0);
await role('authenticated', a);
await count('delete from storage.objects returning id', 1);
await db.query(`insert into storage.objects(bucket_id,name,owner_id) values ('report-photos',$1,$2)`, [path,a]);
await db.query(`update public.reports set photo_path=$1 where id=$2`, [path,id]); checks++;
await role('anon');
await count('select * from public.reports', 1);
await count('select * from public.community_report_feed()', 1);
await denied('select * from public.report_helpful');
await count('select * from storage.objects', 1);
await denied(`insert into storage.objects(bucket_id,name) values ('report-photos',$1)`, [path]);
await denied(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,a]);
await role('authenticated', b);
await count('delete from storage.objects returning id', 0);
await count(`update public.reports set photo_path=null where id=$1 returning id`, 0, [id]);
await denied(`insert into storage.objects(bucket_id,name,owner_id) values ('report-photos',$1,$2)`, [path,b]);
await denied(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,a]);
await db.query(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,b]); checks++;
await denied(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,b]);
let feed = await db.query('select * from public.community_report_feed()');
assert.equal(Number(feed.rows[0].helpful_count), 1);
assert.equal(feed.rows[0].is_helpful, true); checks += 2;
await role('authenticated', a);
await count('select * from public.report_helpful', 0);
await count('delete from public.report_helpful returning report_id', 0);
await role('authenticated', b);
await count('delete from public.report_helpful returning report_id', 1);
await role('authenticated', a, true);
await denied(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,a]);
await denied(`insert into storage.objects(bucket_id,name,owner_id) values ('report-photos',$1,$2)`, [path,a]);
await count(`update public.reports set photo_path=null where id=$1 returning id`, 0, [id]);
await role('anon');
await count("select * from public.community_report_feed('Davao')", 0);
await denied('select * from public.community_report_feed(p_limit => 999)');
await db.exec('reset role');
await db.query('update public.reports set is_visible=false where id=$1', [id]);
await role('anon');
await count('select * from public.reports', 0);
await count('select * from public.community_report_feed()', 0);
await count('select * from storage.objects', 0);
await role('authenticated', b);
await denied(`insert into public.report_helpful(report_id,user_id) values ($1,$2)`, [id,b]);
console.log(`PASS: ${checks} PostgreSQL permission and contract checks (PGlite; mocked Supabase platform schemas).`);
await db.close();

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { metrics, validateEvents, koreanDay, shiftDay } from './metrics.mjs';
import { AnalyticsStore } from './analytics-store.mjs';
import { analyticsRoutes } from './analytics-routes.mjs';

test('exact-day retention excludes incomplete observation; weekly zeroes and widget sessions deduplicate', () => {
  const people = [{ id: 'a', activated_day: '2026-11-09' }, { id: 'b', activated_day: '2026-11-09' }, { id: 'c', activated_day: '2026-11-17' }];
  const activity = [{ install_id: 'a', day: '2026-11-10', recorded: 1 }, { install_id: 'b', day: '2026-11-11', recorded: 0 }, { install_id: 'a', day: '2026-11-16', recorded: 1 }];
  const data = metrics(people, activity, [{ install_id: 'a', session: 's1', day: '2026-11-18', widget: 1 }, { install_id: 'a', session: 's2', day: '2026-11-18', widget: 0 }], '2026-11-18');
  assert.deepEqual(data.d1, { eligible: 2, returned: 1, rate: .5, pending: 1 });
  assert.equal(data.d7.rate, .5);
  assert.equal(data.weeks[0].people, 3); assert.equal(data.weeks[0].average, 1 / 3);
  assert.equal(data.widget.rate, .5);
  assert.equal(metrics([], [], [], '2026-11-18').d1.rate, null);
  assert.equal(koreanDay(Date.parse('2026-11-17T15:00:00Z')), '2026-11-18');
});

function store(t) {
  const db = new DatabaseSync(':memory:'); t.after(() => db.close());
  const state = { storage: {
    sql: { exec: (sql, ...args) => { const stmt = db.prepare(sql); if (/^\s*(SELECT|WITH)/i.test(sql)) return stmt.all(...args); stmt.run(...args); return []; } },
    transactionSync: fn => { db.exec('BEGIN'); try { const result = fn(); db.exec('COMMIT'); return result; } catch (e) { db.exec('ROLLBACK'); throw e; } },
    getAlarm: async () => null, setAlarm: async () => {},
  } };
  return new AnalyticsStore(state);
}
const id = 'a'.repeat(32), secretHash = 'b'.repeat(64), session = 'c'.repeat(32);
const event = (name, extra = {}) => ({ id: 'd'.repeat(32), type: name, at: new Date().toISOString(), session, source: 'app', version: '1.0.0-beta.3', ...extra });
const call = (s, path, data = {}) => s.fetch(new Request('https://internal' + path, { method: 'POST', body: JSON.stringify({ installId: id, secretHash, ...data }) }));

test('SQLite ingestion is idempotent, deletion is authenticated, revoked clients cannot recreate data', async t => {
  const s = store(t);
  assert.equal((await call(s, '/enroll')).status, 200);
  const events = [event('budget_ready'), event('session_start', { id: 'e'.repeat(32) }), event('widget_open', { id: 'f'.repeat(32), source: 'widget_chat' }), event('expense_saved', { id: '1'.repeat(32) })];
  assert.equal((await call(s, '/events', { events })).status, 200);
  assert.equal((await call(s, '/events', { events })).status, 200);
  const report = await (await s.fetch(new Request('https://internal/report'))).json();
  assert.equal(report.totalConsented, 1); assert.equal(report.widget.total, 1); assert.equal(report.widget.count, 1);
  assert.equal(report.weeks[0].totalDays, 1); assert.equal(report.d1.rate, null);
  assert.equal((await call(s, '/delete', { secretHash: '0'.repeat(64) })).status, 401);
  assert.equal((await call(s, '/delete')).status, 200);
  assert.equal((await call(s, '/events', { events })).status, 410);
  assert.equal((await call(s, '/enroll')).status, 409);
  assert.equal((await (await s.fetch(new Request('https://internal/report'))).json()).totalConsented, 0);
});

test('strict event schema rejects financial payloads and invalid timestamps', () => {
  assert.throws(() => validateEvents({ installId: id, events: [event('expense_saved', { amount: 1000 })] }));
  assert.throws(() => validateEvents({ installId: id, events: [event('expense_saved', { at: '2050-01-01T00:00:00Z' })] }));
  assert.throws(() => validateEvents({ installId: id, events: [event('chat_content')] }));
});

test('admin cookie authentication and CSRF origin restrictions', async () => {
  const env = { ANALYTICS_ADMIN_TOKEN: 'admin-' + 'x'.repeat(40), ANALYTICS: { idFromName: n => n, get: () => ({ fetch: async () => Response.json({ safe: true }) }) } };
  assert.equal((await analyticsRoutes(new Request('https://app/admin/data'), env)).status, 401);
  assert.equal((await analyticsRoutes(new Request('https://app/admin/data', { headers: { authorization: 'Bearer tester-code' } }), env)).status, 401);
  const login = () => new Request('https://app/admin/login', { method: 'POST', headers: { 'Content-Type': 'application/json', origin: 'https://app' }, body: JSON.stringify({ key: env.ANALYTICS_ADMIN_TOKEN }) });
  const response = await analyticsRoutes(login(), env);
  assert.equal(response.status, 200);
  const cookie = response.headers.get('set-cookie'); assert.ok(cookie.includes('HttpOnly')); assert.ok(cookie.includes('Secure'));
  assert.equal((await analyticsRoutes(new Request('https://app/admin/data', { headers: { cookie } }), env)).status, 200);
  const foreign = new Request('https://app/admin/login', { method: 'POST', headers: { origin: 'https://evil' }, body: JSON.stringify({ key: env.ANALYTICS_ADMIN_TOKEN }) });
  assert.equal((await analyticsRoutes(foreign, env)).status, 403);
});

test('retention cleanup removes old events and inactive identifiers', async t => {
  const s = store(t); await call(s, '/enroll');
  const old = Date.now() - 91 * 86400000;
  s.sql.exec('UPDATE installs SET last_seen=?', old);
  s.sql.exec('INSERT INTO events VALUES(?,?,?,?,?,?,?,?)', id, 'old', 'app_active', shiftDay(koreanDay(Date.now()), -91), session, 'app', 'test', old);
  await s.alarm();
  const report = await (await s.fetch(new Request('https://internal/report'))).json();
  assert.equal(report.totalConsented, 0); assert.equal(report.daily[0].active, 0);
});

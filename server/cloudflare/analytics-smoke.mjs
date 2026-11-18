// Explicit live verification: creates only a random synthetic installation and deletes it.
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { writeFileSync } from 'node:fs';
process.loadEnvFile('../../.env');
const base = 'https://dontori-chat-beta.promotion-report-worker.workers.dev';
const admin = process.env.ANALYTICS_ADMIN_TOKEN;
const invite = process.env.BETA_TOKENS.split(',')[0].trim();
const installId = randomBytes(16).toString('hex'), deviceSecret = randomBytes(32).toString('hex'), session = randomBytes(16).toString('hex');
const request = (path, token, data) => fetch(base + path, { method: data ? 'POST' : 'GET', headers: { authorization: `Bearer ${token}`, 'Content-Type': 'application/json' }, ...(data ? { body: JSON.stringify(data) } : {}) });
const report = async () => { const r = await request('/admin/data', admin); assert.equal(r.status, 200); return r.json(); };
assert.equal((await fetch(base + '/admin/data')).status, 401);
const before = await report();
try {
  assert.equal((await request('/telemetry/enroll', invite, {installId, deviceSecret, consentVersion: 1})).status, 200);
  const events = ['budget_ready', 'session_start', 'widget_open', 'expense_saved'].map(type => ({id:randomBytes(16).toString('hex'), type, session, source:type === 'widget_open' ? 'widget_chat' : 'app', version:'smoke', at:new Date().toISOString()}));
  for (let i=0;i<2;i++) assert.equal((await request('/telemetry/events', deviceSecret, {installId, events})).status, 200);
  const data = await report();
  assert.equal(data.totalConsented, before.totalConsented + 1);
  assert.equal(data.widget.count, before.widget.count + 1);
  assert.equal(data.widget.total, before.widget.total + 1);
  assert.equal(data.weeks[0].totalDays, before.weeks[0].totalDays + 1);
  const login = await request('/admin/login', '', {key:admin});
  assert.equal(login.status,200);
  assert.equal((await fetch(base+'/admin/data',{headers:{cookie:login.headers.get('set-cookie').split(';')[0]}})).status,200);
} finally {
  assert.equal((await request('/telemetry/delete', deviceSecret, {installId})).status,200);
}
assert.equal((await report()).totalConsented,before.totalConsented);
writeFileSync('../../../2026-11-13/dtr-android-git-c-users-imjun/outputs/DTR-analytics-admin.txt', `돈토리 베타 관리자 전용 — 테스터에게 공유하지 마세요.\n\n대시보드: ${base}/admin\n관리자 접근 키: ${admin}\n\n테스터는 기존 베타 초대 코드를 사용합니다. 관리자 키는 APK에 포함되지 않습니다.\n`, 'utf8');
console.log('PASS: live auth, ingestion, deduplication, dashboard aggregation, cookie login, deletion; synthetic data removed. Owner access file saved.');

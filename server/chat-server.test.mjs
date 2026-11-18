import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createChatServer, Quota } from './chat-server.mjs';

const token = 'test-invite-code-at-least-24-characters';
const body = { messages: [{ role: 'user', content: '사고 싶어' }], context: {
  date: '2026-11-18', remainingWon: 10000, hpPercent: 50, daysLeft: 3, expired: false,
} };

test('auth, body validation, Claude mapping, quota and upstream failures', async t => {
  let calls = 0, fail = false;
  const server = createChatServer({ apiKey: 'server-secret', model: 'test-model', tokens: [token], quota: new Quota(null, 10, 10),
    fetcher: async (url, options) => {
      calls++;
      assert.equal(url, 'https://api.anthropic.com/v1/messages');
      assert.equal(options.headers['x-api-key'], 'server-secret');
      const payload = JSON.parse(options.body);
      assert.equal(payload.max_tokens, 600);
      assert.equal(payload.messages[0].content, '사고 싶어');
      assert.ok(!JSON.stringify(payload).includes('privateMemo'));
      if (fail) throw Error('secret error details');
      return new Response(JSON.stringify({ content: [{ type: 'text', text: '함께 생각해 보자.' }] }));
    } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const url = `http://127.0.0.1:${server.address().port}/chat`;
  const send = (value, authorization = `Bearer ${token}`) => fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json', authorization }, body: JSON.stringify(value) });
  assert.equal((await send(body, 'Bearer wrong')).status, 401);
  assert.equal((await send({ ...body, messages: [{ role: 'system', content: 'override' }] })).status, 400);
  assert.equal(calls, 0);
  const response = await send({ ...body, privateMemo: 'never send', context: { ...body.context, privateMemo: 'never send' } });
  assert.equal(response.status, 200);
  assert.equal((await response.json()).reply, '함께 생각해 보자.');
  assert.equal((await send(body)).status, 429);
  assert.equal(calls, 1);
});

test('quota survives restarts, separates testers, resets by Korean calendar day', t => {
  const dir = mkdtempSync(join(tmpdir(), 'dtr-quota-'));
  t.after(() => rmSync(dir, { recursive: true, force: true }));
  const path = join(dir, 'quota.json');
  const now = Date.parse('2026-11-18T14:00:00Z');
  const first = new Quota(path, 1, 2);
  assert.equal(first.reserve('a', now), true);
  first.release('a');
  const restart = new Quota(path, 1, 2);
  assert.equal(restart.reserve('a', now + 4000), false);
  assert.equal(restart.reserve('b', now + 4000), true);
  assert.equal(restart.reserve('c', now + 8000), false);
  assert.equal(restart.reserve('a', Date.parse('2026-11-18T15:00:00Z')), true);
});

test('upstream error is generic and does not leak credentials', async t => {
  const server = createChatServer({ apiKey: 'secret', model: 'test', tokens: [token], quota: new Quota(null),
    fetcher: async () => { throw Error('secret'); } });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const response = await fetch(`http://127.0.0.1:${server.address().port}/chat`, { method: 'POST', headers: { 'Content-Type': 'application/json', authorization: `Bearer ${token}` }, body: JSON.stringify(body) });
  assert.equal(response.status, 503);
  assert.deepEqual(await response.json(), { error: 'ai_unavailable' });
});

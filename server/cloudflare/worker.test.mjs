import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ChatQuota, handleChat } from './worker.mjs';

const token = 'test-invite-abcdefghijklmnopqrstuvwxyz';
const payload = { messages: [{ role: 'user', content: '사고 싶어' }], context: { date: '2026-11-18', remainingWon: 10000, hpPercent: 50, daysLeft: 7, expired: false } };
const request = (body = payload, auth = token) => new Request('https://example.com/chat', { method: 'POST', headers: { 'Content-Type': 'application/json', authorization: `Bearer ${auth}` }, body: JSON.stringify(body) });

test('worker authenticates and validates before reserving or calling Claude', async () => {
  let count = 0;
  const env = { ANTHROPIC_API_KEY: 'test-key', ANTHROPIC_MODEL: 'test-model', BETA_TOKENS: token,
    QUOTA: { idFromName: name => name, get: () => ({ fetch: async () => { count++; return new Response('{}'); } }) } };
  assert.equal((await handleChat(request(payload, 'wrong'), env)).status, 401);
  assert.equal((await handleChat(request({ ...payload, messages: [{ role: 'system', content: 'injection' }] }), env)).status, 400);
  assert.equal(count, 0);
  const response = await handleChat(request(), env, async (url, options) => {
    assert.equal(url, 'https://api.anthropic.com/v1/messages');
    assert.equal(JSON.parse(options.body).max_tokens, 600);
    return new Response(JSON.stringify({ content: [{ type: 'text', text: '함께 생각해 보자.' }] }));
  });
  assert.equal(response.status, 200);
  assert.equal(count, 1);
  assert.deepEqual(await response.json(), { reply: '함께 생각해 보자.' });
  env.QUOTA.get = () => ({ fetch: async () => new Response('{}', { status: 429 }) });
  assert.equal((await handleChat(request(), env, () => { throw Error('must not call'); })).status, 429);
});

test('durable quota retains counters across object instances and prevents concurrent excess', async () => {
  const values = new Map(); let pending = Promise.resolve();
  const storage = { transaction: fn => {
    const task = pending.then(() => fn({ get: async key => structuredClone(values.get(key)), put: async (key, value) => values.set(key, structuredClone(value)) }));
    pending = task.catch(() => {}); return task;
  } };
  const env = { DAILY_LIMIT: '1', GLOBAL_DAILY_LIMIT: '2' };
  const make = () => new ChatQuota({ storage }, env);
  const reserve = (object, id) => object.fetch(new Request('https://quota/reserve', { method: 'POST', body: JSON.stringify({ id: id.repeat(64) }) }));
  const replies = await Promise.all([reserve(make(), 'a'), reserve(make(), 'a'), reserve(make(), 'b'), reserve(make(), 'c')]);
  assert.equal(replies.filter(r => r.status === 200).length, 2);
  assert.equal((await reserve(make(), 'a')).status, 429);
  assert.equal(values.get('current').total, 2);
});

import { validateBody, system } from './chat-core.mjs';
export { validateBody } from './chat-core.mjs';
import http from 'node:http';
import { createHash, timingSafeEqual } from 'node:crypto';
import { mkdirSync, readFileSync, writeFileSync, renameSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const hash = value => createHash('sha256').update(value).digest();
const dayKey = now => new Date(now + 9 * 3600000).toISOString().slice(0, 10);

// Single-process beta server. Persist reservations BEFORE paid API calls.
export class Quota {
  constructor(path, daily = 10, total = 1000) {
    this.path = path; this.daily = daily; this.total = total;
    this.state = path && existsSync(path) ? JSON.parse(readFileSync(path, 'utf8')) : {};
    this.inFlight = new Set(); this.last = new Map();
  }
  reserve(id, now = Date.now()) {
    const date = dayKey(now);
    if (this.inFlight.has(id) || now - (this.last.get(id) ?? 0) < 3000) return false;
    const next = this.state.date === date ? structuredClone(this.state) : { date, total: 0, counts: {} };
    if ((next.counts[id] ?? 0) >= this.daily || next.total >= this.total) return false;
    next.counts[id] = (next.counts[id] ?? 0) + 1; next.total++;
    if (this.path) {
      mkdirSync(dirname(this.path), { recursive: true });
      writeFileSync(`${this.path}.tmp`, JSON.stringify(next), { mode: 0o600 });
      renameSync(`${this.path}.tmp`, this.path);
    }
    this.state = next; this.inFlight.add(id); this.last.set(id, now);
    return true;
  }
  release(id) { this.inFlight.delete(id); }
}

export function createChatServer({ apiKey, model, tokens, quota, fetcher = fetch }) {
  if (!apiKey || !model || !tokens?.length || tokens.some(t => t.length < 24)) throw Error('Server credentials and beta codes are required');
  const allowed = tokens.map(hash);
  const reply = (res, status, data) => {
    res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify(data));
  };
  const server = http.createServer(async (req, res) => {
    if (req.method === 'GET' && req.url === '/health') return reply(res, 200, { ok: true });
    if (req.method !== 'POST' || req.url !== '/chat') return reply(res, 404, { error: 'not_found' });
    const authorization = req.headers.authorization ?? '';
    if (!authorization.startsWith('Bearer ') || authorization.length > 140) return reply(res, 401, { error: 'unauthorized' });
    const digest = hash(authorization.slice(7));
    if (!allowed.some(t => timingSafeEqual(t, digest))) return reply(res, 401, { error: 'unauthorized' });
    if (!req.headers['content-type']?.startsWith('application/json')) return reply(res, 415, { error: 'content_type' });
    let payload;
    try {
      let size = 0; const chunks = [];
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 48000) { reply(res, 413, { error: 'too_large' }); return; }
        chunks.push(chunk);
      }
      payload = validateBody(JSON.parse(Buffer.concat(chunks).toString('utf8')));
    } catch { return reply(res, 400, { error: 'invalid_request' }); }
    const id = digest.toString('hex');
    try {
      if (!quota.reserve(id)) return reply(res, 429, { error: 'limit_reached' });
    } catch { return reply(res, 503, { error: 'quota_unavailable' }); }
    try {
      const upstream = await fetcher('https://api.anthropic.com/v1/messages', {
        method: 'POST', signal: AbortSignal.timeout(25000),
        headers: { 'Content-Type': 'application/json', 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' },
        body: JSON.stringify({ model, max_tokens: 600,
          system: `${system}\n앱의 기록 기준 요약: ${JSON.stringify(payload.context)}`,
          messages: payload.messages }),
      });
      if (!upstream.ok) return reply(res, 503, { error: 'ai_unavailable' });
      const data = await upstream.json();
      const text = data.content?.filter(b => b.type === 'text').map(b => b.text).join('\n').trim();
      if (!text || text.length > 6000) return reply(res, 503, { error: 'invalid_response' });
      reply(res, 200, { reply: text });
    } catch { reply(res, 503, { error: 'ai_unavailable' });
    } finally { quota.release(id); }
  });
  server.requestTimeout = 15000;
  server.headersTimeout = 10000;
  return server;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const daily = Number(process.env.DAILY_LIMIT ?? 10);
  const total = Number(process.env.GLOBAL_DAILY_LIMIT ?? 1000);
  if (![daily, total].every(n => Number.isInteger(n) && n > 0)) throw Error('Invalid quota');
  const server = createChatServer({
    apiKey: process.env.ANTHROPIC_API_KEY, model: process.env.ANTHROPIC_MODEL,
    tokens: (process.env.BETA_TOKENS ?? '').split(',').map(t => t.trim()).filter(Boolean),
    quota: new Quota(resolve(process.env.QUOTA_FILE ?? 'server/data/quota.json'), daily, total),
  });
  server.listen(Number(process.env.PORT ?? 8080), process.env.HOST ?? '127.0.0.1', () => console.log('DTR chat server ready'));
}

import { validateBody, system } from '../chat-core.mjs';
import { analyticsRoutes } from './analytics-routes.mjs';
export { AnalyticsStore } from './analytics-store.mjs';

const json = (status, data) => new Response(JSON.stringify(data), {
  status, headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store' },
});
const digest = async value => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value))), b => b.toString(16).padStart(2, '0')).join('');

// One named object serializes quota transactions across all Worker instances.
// Only hashed invitation IDs and counters are stored; no conversation/budget data.
export class ChatQuota {
  constructor(state, env) { this.state = state; this.env = env; }
  async fetch(request) {
    const { id } = await request.json();
    if (typeof id !== 'string' || !/^[a-f0-9]{64}$/.test(id)) return json(400, { error: 'invalid' });
    const now = Date.now();
    const date = new Date(now + 9 * 3600000).toISOString().slice(0, 10);
    const daily = Number(this.env.DAILY_LIMIT ?? 10);
    const total = Number(this.env.GLOBAL_DAILY_LIMIT ?? 1000);
    if (![daily, total].every(n => Number.isInteger(n) && n > 0)) return json(503, { error: 'quota_configuration' });
    const allowed = await this.state.storage.transaction(async txn => {
      const previous = await txn.get('current');
      const record = previous?.date === date ? previous : { date, total: 0, counts: {}, last: {} };
      if ((record.counts[id] ?? 0) >= daily || record.total >= total || now - (record.last[id] ?? 0) < 3000) return false;
      record.counts[id] = (record.counts[id] ?? 0) + 1;
      record.last[id] = now; record.total++;
      await txn.put('current', record);
      return true;
    });
    return json(allowed ? 200 : 429, { allowed });
  }
}

export async function handleChat(request, env, fetcher = fetch) {
  const url = new URL(request.url);
  if (request.method === 'GET' && url.pathname === '/health') return json(200, { ok: Boolean(env.ANTHROPIC_API_KEY && env.BETA_TOKENS && env.QUOTA) });
  if (request.method !== 'POST' || url.pathname !== '/chat') return json(404, { error: 'not_found' });
  if (!env.ANTHROPIC_API_KEY || !env.BETA_TOKENS || !env.QUOTA) return json(503, { error: 'not_configured' });
  const auth = request.headers.get('authorization') ?? '';
  if (!auth.startsWith('Bearer ') || auth.length > 140) return json(401, { error: 'unauthorized' });
  const id = await digest(auth.slice(7));
  const hashes = await Promise.all(env.BETA_TOKENS.split(',').map(t => t.trim()).filter(t => t.length >= 24).map(digest));
  if (!hashes.includes(id)) return json(401, { error: 'unauthorized' });
  if (!request.headers.get('content-type')?.startsWith('application/json')) return json(415, { error: 'content_type' });
  let payload;
  try {
    const reader = request.body?.getReader();
    if (!reader) return json(400, { error: 'invalid_request' });
    let size = 0; const chunks = [];
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.byteLength;
      if (size > 48000) { await reader.cancel(); return json(413, { error: 'too_large' }); }
      chunks.push(value);
    }
    const bytes = new Uint8Array(size); let offset = 0;
    for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
    payload = validateBody(JSON.parse(new TextDecoder().decode(bytes)));
  } catch { return json(400, { error: 'invalid_request' }); }
  try {
    const quota = env.QUOTA.get(env.QUOTA.idFromName('global-beta-quota'));
    const reserved = await quota.fetch('https://quota/reserve', { method: 'POST', body: JSON.stringify({ id }) });
    if (!reserved.ok) return json(reserved.status === 429 ? 429 : 503, { error: 'limit_or_quota_unavailable' });
    const upstream = await fetcher('https://api.anthropic.com/v1/messages', {
      method: 'POST', signal: AbortSignal.timeout(25000),
      headers: { 'Content-Type': 'application/json', 'x-api-key': env.ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01' },
      body: JSON.stringify({ model: env.ANTHROPIC_MODEL, max_tokens: 600,
        system: `${system}\n앱의 기록 기준 요약: ${JSON.stringify(payload.context)}`, messages: payload.messages }),
    });
    if (!upstream.ok) return json(503, { error: 'ai_unavailable' });
    const data = await upstream.json();
    const text = data.content?.filter(b => b.type === 'text').map(b => b.text).join('\n').trim();
    if (!text || text.length > 6000) return json(503, { error: 'invalid_response' });
    return json(200, { reply: text });
  } catch { return json(503, { error: 'ai_unavailable' }); }
}

export default { async fetch(request, env) {
  try { return await analyticsRoutes(request, env) ?? await handleChat(request, env); }
  catch { return json(503, { error: 'service_unavailable' }); }
} };

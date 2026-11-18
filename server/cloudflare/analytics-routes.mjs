import { adminHtml, adminJs } from './admin-page.mjs';
import { validateEvents } from './metrics.mjs';
const json = (status, data, headers = {}) => Response.json(data, { status, headers: { 'Cache-Control': 'no-store', ...headers } });
const hash = async text => Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))), b => b.toString(16).padStart(2, '0')).join('');
async function signature(value, secret) {
  const key = await crypto.subtle.importKey('raw', new TextEncoder().encode(secret), { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  return Array.from(new Uint8Array(await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(value))), b => b.toString(16).padStart(2, '0')).join('');
}
async function isAdmin(request, env) {
  if (!env.ANALYTICS_ADMIN_TOKEN) return false;
  const bearer = request.headers.get('authorization')?.slice(7);
  if (request.headers.get('authorization')?.startsWith('Bearer ') && bearer?.length < 200 && await hash(bearer) === await hash(env.ANALYTICS_ADMIN_TOKEN)) return true;
  const cookie = request.headers.get('cookie')?.split(';').map(s => s.trim()).find(s => s.startsWith('dtr_admin='))?.slice(10);
  if (!cookie) return false;
  const [expires, sig] = cookie.split('.');
  return /^\d{13}$/.test(expires) && Number(expires) > Date.now() && Number(expires) <= Date.now() + 86400000 && sig === await signature(expires, env.ANALYTICS_ADMIN_TOKEN);
}
async function readJson(request, limit) {
  const reader = request.body?.getReader(); if (!reader) throw Error();
  let bytes = 0, text = ''; const decoder = new TextDecoder();
  while (true) { const { done, value } = await reader.read(); if (done) break;
    bytes += value.length; if (bytes > limit) { await reader.cancel(); throw Error(); } text += decoder.decode(value, { stream: true }); }
  return JSON.parse(text + decoder.decode());
}

export async function analyticsRoutes(request, env) {
  const url = new URL(request.url), path = url.pathname;
  if (!path.startsWith('/admin') && !path.startsWith('/telemetry/')) return null;
  const store = () => env.ANALYTICS.get(env.ANALYTICS.idFromName('beta-analytics'));
  if (path === '/admin' && request.method === 'GET') return new Response(adminHtml, { headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store', 'Content-Security-Policy': "default-src 'none'; script-src 'self'; style-src 'unsafe-inline'; connect-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'none'", 'Referrer-Policy': 'no-referrer', 'X-Content-Type-Options': 'nosniff' } });
  if (path === '/admin/app.js' && request.method === 'GET') return new Response(adminJs, { headers: { 'Content-Type': 'text/javascript; charset=utf-8', 'Cache-Control': 'no-store' } });
  if (path.startsWith('/admin') && request.method === 'POST' && request.headers.get('origin') && request.headers.get('origin') !== url.origin) return json(403, { error: 'origin' });
  if (path === '/admin/login' && request.method === 'POST') {
    let body; try { body = await readJson(request, 1000); } catch { return json(400, { error: 'invalid' }); }
    if (!env.ANALYTICS_ADMIN_TOKEN || typeof body.key !== 'string' || body.key.length > 200 || await hash(body.key) !== await hash(env.ANALYTICS_ADMIN_TOKEN)) return json(401, { error: 'unauthorized' });
    const expires = String(Date.now() + 86400000);
    return json(200, { ok: true }, { 'Set-Cookie': `dtr_admin=${expires}.${await signature(expires, env.ANALYTICS_ADMIN_TOKEN)}; HttpOnly; Secure; SameSite=Strict; Path=/admin; Max-Age=86400` });
  }
  if (path === '/admin/logout' && request.method === 'POST') return json(200, { ok: true }, { 'Set-Cookie': 'dtr_admin=; HttpOnly; Secure; SameSite=Strict; Path=/admin; Max-Age=0' });
  if (path === '/admin/data' && request.method === 'GET') {
    if (!await isAdmin(request, env)) return json(401, { error: 'unauthorized' });
    const response = await store().fetch('https://analytics/report');
    return new Response(response.body, { status: response.status, headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' } });
  }
  if (!['/telemetry/enroll', '/telemetry/events', '/telemetry/delete'].includes(path) || request.method !== 'POST') return json(404, { error: 'not_found' });
  if (!env.ANALYTICS) return json(503, { error: 'not_configured' });
  const authorization = request.headers.get('authorization') ?? '';
  if (!authorization.startsWith('Bearer ') || authorization.length > 140) return json(401, { error: 'unauthorized' });
  const secret = authorization.slice(7);
  let body; try { body = await readJson(request, 20000); } catch { return json(400, { error: 'invalid' }); }
  if (path === '/telemetry/enroll') {
    const codes = await Promise.all((env.BETA_TOKENS ?? '').split(',').map(s => hash(s.trim())));
    if (!codes.includes(await hash(secret))) return json(401, { error: 'invitation' });
    if (!body || Object.keys(body).some(k => !['installId', 'deviceSecret', 'consentVersion'].includes(k)) || body.consentVersion !== 1 || !/^[a-f0-9]{64}$/.test(body.deviceSecret)) return json(400, { error: 'consent' });
    return store().fetch('https://analytics/enroll', { method: 'POST', body: JSON.stringify({ installId: body.installId, secretHash: await hash(body.deviceSecret) }) });
  }
  if (!/^[a-f0-9]{64}$/.test(secret)) return json(401, { error: 'unauthorized' });
  if (path === '/telemetry/events') { try { validateEvents(body); } catch { return json(400, { error: 'invalid_events' }); } }
  else if (!body || Object.keys(body).some(k => k !== 'installId')) return json(400, { error: 'invalid' });
  return store().fetch(`https://analytics/${path.endsWith('/delete') ? 'delete' : 'events'}`, { method: 'POST', body: JSON.stringify({ ...body, secretHash: await hash(secret) }) });
}

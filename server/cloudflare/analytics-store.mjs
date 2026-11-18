import { DAY, koreanDay, metrics, validateEvents } from './metrics.mjs';
const json = (status, data) => Response.json(data, { status });

export class AnalyticsStore {
  constructor(state) {
    this.state = state; this.sql = state.storage.sql;
    this.sql.exec(`CREATE TABLE IF NOT EXISTS installs (id TEXT PRIMARY KEY, secret_hash TEXT NOT NULL, joined INTEGER NOT NULL, last_seen INTEGER NOT NULL, activated_day TEXT, revoked INTEGER NOT NULL DEFAULT 0)`);
    this.sql.exec(`CREATE TABLE IF NOT EXISTS events (install_id TEXT NOT NULL, id TEXT NOT NULL, type TEXT NOT NULL, day TEXT NOT NULL, session TEXT NOT NULL, source TEXT NOT NULL, version TEXT NOT NULL, received INTEGER NOT NULL, PRIMARY KEY(install_id,id))`);
    this.sql.exec('CREATE INDEX IF NOT EXISTS events_day ON events(day)');
  }
  prune(now = Date.now()) {
    const cutoff = now - 90 * DAY;
    this.sql.exec('DELETE FROM events WHERE day < ?', koreanDay(cutoff));
    this.sql.exec('DELETE FROM installs WHERE last_seen < ? AND id NOT IN (SELECT install_id FROM events)', cutoff);
  }
  async alarm() {
    this.prune();
    if ([...this.sql.exec('SELECT id FROM installs LIMIT 1')].length) await this.state.storage.setAlarm(Date.now() + DAY);
  }
  async fetch(request) {
    const path = new URL(request.url).pathname;
    const now = Date.now(); this.prune(now);
    if (path === '/report') {
      const installs = [...this.sql.exec('SELECT id,activated_day FROM installs WHERE revoked=0')];
      const activity = [...this.sql.exec("SELECT install_id,day,MAX(type='expense_saved') AS recorded FROM events GROUP BY install_id,day")];
      const sessions = [...this.sql.exec("SELECT install_id,session,day,MAX(type='widget_open') AS widget FROM events WHERE type IN ('session_start','widget_open') GROUP BY install_id,session,day")];
      return json(200, metrics(installs, activity, sessions, koreanDay(now)));
    }
    const body = await request.json();
    const { installId, secretHash } = body;
    if (!/^[a-f0-9]{32}$/.test(installId) || !/^[a-f0-9]{64}$/.test(secretHash)) return json(400, { error: 'invalid' });
    const existing = [...this.sql.exec('SELECT * FROM installs WHERE id=?', installId)][0];
    if (path === '/enroll') {
      if (existing && (existing.secret_hash !== secretHash || existing.revoked)) return json(409, { error: 'existing' });
      this.sql.exec('INSERT OR IGNORE INTO installs(id,secret_hash,joined,last_seen) VALUES(?,?,?,?)', installId, secretHash, now, now);
      if (!await this.state.storage.getAlarm()) await this.state.storage.setAlarm(now + DAY);
      return json(200, { ok: true });
    }
    if (!existing || existing.secret_hash !== secretHash) return json(401, { error: 'unauthorized' });
    if (path === '/delete') {
      this.state.storage.transactionSync(() => {
        this.sql.exec('DELETE FROM events WHERE install_id=?', installId);
        this.sql.exec('UPDATE installs SET revoked=1,activated_day=NULL,last_seen=? WHERE id=?', now, installId);
      });
      return json(200, { ok: true });
    }
    if (existing.revoked) return json(410, { error: 'revoked' });
    if (path !== '/events') return json(404, { error: 'not_found' });
    let events;
    try { ({ events } = validateEvents({ installId, events: body.events }, now)); } catch { return json(400, { error: 'invalid_events' }); }
    const count = [...this.sql.exec('SELECT count(*) AS n FROM events WHERE install_id=? AND received>=?', installId, now - DAY)][0].n;
    if (count + events.length > 2000) return json(429, { error: 'limit' });
    this.state.storage.transactionSync(() => {
      for (const e of events) {
        this.sql.exec('INSERT OR IGNORE INTO events VALUES(?,?,?,?,?,?,?,?)', installId, e.id, e.type, e.day, e.session, e.source, e.version, now);
        if (e.type === 'budget_ready') this.sql.exec('UPDATE installs SET activated_day=CASE WHEN activated_day IS NULL OR activated_day>? THEN ? ELSE activated_day END WHERE id=?', e.day, e.day, installId);
      }
      this.sql.exec('UPDATE installs SET last_seen=? WHERE id=?', now, installId);
    });
    return json(200, { accepted: events.map(e => e.id) });
  }
}

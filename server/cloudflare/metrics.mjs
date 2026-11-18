export const DAY = 86400000;
export const koreanDay = at => new Date(at + 9 * 3600000).toISOString().slice(0, 10);
export const shiftDay = (day, n) => new Date(Date.parse(`${day}T00:00:00Z`) + n * DAY).toISOString().slice(0, 10);
const ratio = (n, d) => d ? n / d : null;

export function metrics(installs, activity, sessions, today) {
  const from = shiftDay(today, -27);
  const people = installs.filter(p => p.activated_day);
  const active = new Set(activity.map(a => `${a.install_id}:${a.day}`));
  const retention = (group, offset) => {
    const eligible = group.filter(p => shiftDay(p.activated_day, offset) < today);
    const returned = eligible.filter(p => active.has(`${p.id}:${shiftDay(p.activated_day, offset)}`)).length;
    return { eligible: eligible.length, returned, rate: ratio(returned, eligible.length), pending: group.length - eligible.length };
  };
  const cohorts = [...new Set(people.map(p => p.activated_day))].filter(d => d >= from).sort().reverse().map(day => {
    const group = people.filter(p => p.activated_day === day);
    return { day, size: group.length, d1: retention(group, 1), d7: retention(group, 7) };
  });
  const current = people.filter(p => p.activated_day >= from);
  const dow = new Date(`${today}T00:00:00Z`).getUTCDay();
  const monday = shiftDay(today, -((dow + 6) % 7));
  const weeks = Array.from({ length: 4 }, (_, i) => {
    const start = shiftDay(monday, -7 * i), end = [shiftDay(start, 6), today].sort()[0];
    const eligible = people.filter(p => p.activated_day <= end);
    const ids = new Set(eligible.map(p => p.id));
    const days = activity.filter(a => ids.has(a.install_id) && a.day >= start && a.day <= end && a.recorded);
    return { start, end, partial: i === 0, people: eligible.length, totalDays: days.length,
      average: ratio(days.length, eligible.length), recordingPeople: new Set(days.map(a => a.install_id)).size };
  });
  const recentSessions = sessions.filter(s => s.day >= from && s.day <= today);
  const widget = recentSessions.filter(s => s.widget).length;
  return { today, from, totalConsented: installs.length, activated: people.length,
    d1: retention(current, 1), d7: retention(current, 7), cohorts, weeks,
    widget: { total: recentSessions.length, count: widget, rate: ratio(widget, recentSessions.length) },
    daily: Array.from({ length: 28 }, (_, i) => {
      const day = shiftDay(today, -i), rows = activity.filter(a => a.day === day);
      return { day, active: rows.length, recording: rows.filter(a => a.recorded).length };
    }) };
}

export function validateEvents(body, now = Date.now()) {
  if (!body || Object.keys(body).some(k => !['installId', 'events'].includes(k)) || !/^[a-f0-9]{32}$/.test(body.installId) || !Array.isArray(body.events) || body.events.length < 1 || body.events.length > 50) throw Error('invalid');
  const events = body.events.map(e => {
    if (!e || Object.keys(e).some(k => !['id', 'type', 'at', 'session', 'source', 'version'].includes(k)) ||
      !/^[a-f0-9]{32}$/.test(e.id) || !/^[a-f0-9]{32}$/.test(e.session) ||
      !['app_active', 'session_start', 'widget_open', 'expense_saved', 'budget_ready'].includes(e.type) ||
      !['app', 'widget_chat', 'widget_expense'].includes(e.source) ||
      typeof e.version !== 'string' || !/^[a-zA-Z0-9.+-]{1,40}$/.test(e.version) ||
      typeof e.at !== 'string' || !e.at.endsWith('Z')) throw Error('event');
    const at = Date.parse(e.at);
    if (!Number.isFinite(at) || at < now - 30 * DAY || at > now + 5 * 60000) throw Error('time');
    return { ...e, day: koreanDay(Math.min(at, now)) };
  });
  return { installId: body.installId, events };
}

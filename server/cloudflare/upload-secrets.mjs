import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
process.loadEnvFile(fileURLToPath(new URL('../../.env', import.meta.url)));
const secrets = { ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY, BETA_TOKENS: process.env.BETA_TOKENS };
if (process.env.ANALYTICS_ADMIN_TOKEN) secrets.ANALYTICS_ADMIN_TOKEN = process.env.ANALYTICS_ADMIN_TOKEN;
if (Object.values(secrets).some(value => !value)) throw Error('Required local settings are missing');
// Pipe directly to Wrangler. Never put secret values in command arguments or logs.
const result = spawnSync(process.execPath, [fileURLToPath(new URL('node_modules/wrangler/bin/wrangler.js', import.meta.url)), 'secret', 'bulk'], {
  cwd: fileURLToPath(new URL('.', import.meta.url)), input: JSON.stringify(secrets), encoding: 'utf8', windowsHide: true,
});
console.log(result.status === 0 ? 'Runtime secrets uploaded.' : 'Secret upload failed; no secret output displayed.');
process.exitCode = result.status ?? 1;

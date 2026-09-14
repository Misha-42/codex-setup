// opencode-go-proxy.cjs — локальный Anthropic-совместимый прокси до OpenCode Go.
// Зачем: Claude Code ходит на <base>/v1/messages; прокси добавляет ключ и
// заголовок x-opencode-session (стабильный на диалог) и логирует трафик.
// Запуск: node opencode-go-proxy.cjs  (порт 1889, ключ из OPENCODE_GO_KEY или auth.json)
const http = require('http');
const https = require('https');
const fs = require('fs');
const os = require('os');
const path = require('path');
const crypto = require('crypto');

const PORT = Number(process.env.OPENCODE_GO_PORT || 1889);
const LOG = process.env.OPENCODE_GO_LOG || path.join(__dirname, 'opencode-go-proxy.log');
const DEBUG = process.env.OPENCODE_GO_DEBUG === '1';

function loadKey() {
  if (process.env.OPENCODE_GO_KEY) return process.env.OPENCODE_GO_KEY;
  try {
    const authPath = path.join(os.homedir(), '.local', 'share', 'opencode', 'auth.json');
    const auth = JSON.parse(fs.readFileSync(authPath, 'utf8'));
    return auth['opencode-go'] && auth['opencode-go'].key;
  } catch (e) {
    return null;
  }
}
const KEY = loadKey();
if (!KEY) {
  console.error('opencode-go: ключ не найден (OPENCODE_GO_KEY или ~/.local/share/opencode/auth.json)');
  process.exit(1);
}

// Стабильный sid уровня процесса — фолбэк, если в запросе нет маркеров диалога.
// ВАЖНО: нельзя генерировать новый sid на каждый запрос — бэкенд OpenCode Go
// использует x-opencode-session для маршрутизации на один и тот же узел,
// и случайный sid = каждый запрос «новая сессия» = prompt-кэш никогда не попадает.
const PROCESS_SID = crypto.randomUUID();

// Достаём стабильный идентификатор диалога из тела запроса Claude Code:
// metadata.user_id — JSON-строка вида {"device_id":...,"session_id":"<uuid>"}.
function extractSid(bodyBuf, headerSid) {
  if (headerSid) return String(headerSid);
  try {
    const j = JSON.parse(bodyBuf.toString('utf8'));
    const uid = j && j.metadata && j.metadata.user_id;
    if (typeof uid === 'string' && uid) {
      const m = uid.match(/"session_id"\s*:\s*"([0-9a-fA-F-]{8,})"/);
      if (m) return m[1];
      if (/^[0-9a-fA-F-]{8,}$/.test(uid)) return uid;
      // произвольная строка — стабилизируем хэшем в формат UUID
      const h = crypto.createHash('sha256').update(uid).digest('hex');
      return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20, 32)}`;
    }
  } catch (e) {}
  return PROCESS_SID;
}

function log(line) {
  try { fs.appendFileSync(LOG, line + '\n'); } catch (e) {}
}
// Ротация лога при старте: не даём файлу расти бесконечно.
try {
  if (fs.existsSync(LOG) && fs.statSync(LOG).size > 2 * 1024 * 1024) fs.truncateSync(LOG, 0);
} catch (e) {}

const server = http.createServer((req, res) => {
  // Health-probe Claude Code (Bun) — отвечаем 200, чтобы не сыпалось 404.
  if (req.url === '/api/hello') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end('{"ok":true}');
    return;
  }
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const sid = extractSid(body, req.headers['x-opencode-session']);
    const headers = { ...req.headers };
    delete headers['host'];
    delete headers['content-length'];
    headers['authorization'] = 'Bearer ' + KEY;
    headers['x-api-key'] = KEY;
    headers['x-opencode-session'] = sid;

    log(`\n=== ${new Date().toISOString()} ${req.method} ${req.url} sid=${sid}`);
    if (DEBUG) {
      log('REQ-HEADERS ' + JSON.stringify(req.headers));
      if (body.length) log('REQ-BODY ' + body.toString('utf8').slice(0, 8000));
      if (body.length > 8000) log('REQ-BODY-TAIL ' + body.toString('utf8').slice(-3000));
    }

    const opts = {
      hostname: 'opencode.ai',
      path: '/zen/go' + req.url,
      method: req.method,
      headers,
    };
    // Retry при обрывах/транзиентных ошибках: сеть + 5xx. 429 НЕ ретраим —
    // у Go это квота (сброс раз в ~5ч), бесполезно. Задержки 0,2,4,...,256с
    // (~8,5 мин суммарно, укладывается в API_TIMEOUT_MS клиента).
    const DELAYS = [0, 2, 4, 8, 16, 32, 64, 128, 256].map(s => s * 1000);
    const RETRY_STATUS = new Set([500, 502, 503, 504]);
    const sleep = (ms) => new Promise(r => setTimeout(r, ms));
    let clientGone = false;
    res.on('close', () => { clientGone = true; });

    (async () => {
      for (let attempt = 0; ; attempt++) {
        if (clientGone) return;
        const result = await new Promise((resolve) => {
          const proxied = https.request(opts, (pres) => resolve({ type: 'response', pres }));
          proxied.setTimeout(120000, () => proxied.destroy(Object.assign(new Error('connect timeout'), { code: 'ETIMEDOUT' })));
          proxied.on('error', (e) => resolve({ type: 'error', err: e }));
          proxied.end(body);
        });

        if (result.type === 'error') {
          log(`ERR ${req.url} sid=${sid} attempt=${attempt + 1} ${result.err.code || result.err.message}`);
          if (attempt < DELAYS.length && !clientGone) { await sleep(DELAYS[attempt]); continue; }
          if (!clientGone && !res.headersSent) {
            res.writeHead(502, { 'content-type': 'application/json' });
            res.end(JSON.stringify({ type: 'error', error: { type: 'proxy_error', message: String(result.err.message || result.err.code) } }));
          }
          return;
        }

        const pres = result.pres;
        if (RETRY_STATUS.has(pres.statusCode) && attempt < DELAYS.length && !clientGone) {
          log(`RETRY ${req.url} sid=${sid} attempt=${attempt + 1} status=${pres.statusCode} delay=${DELAYS[attempt] / 1000}s`);
          pres.resume();
          await sleep(DELAYS[attempt]);
          continue;
        }

        log(`RESP ${req.url} -> ${pres.statusCode} (attempts=${attempt + 1})`);
        res.writeHead(pres.statusCode, pres.headers);
        pres.on('error', () => { try { res.destroy(); } catch (e) {} });
        res.on('error', () => { try { pres.destroy(); } catch (e) {} });
        pres.pipe(res);
        return;
      }
    })().catch((e) => {
      log(`FATAL-HANDLED ${e && e.message}`);
      try { if (!res.headersSent) res.writeHead(502); res.end(); } catch (e2) {}
    });
  });
});
// Прокси не должен падать ни при каких обстоятельствах.
process.on('uncaughtException', (e) => log(`UNCAUGHT ${e && e.stack || e}`));
process.on('unhandledRejection', (e) => log(`UNHANDLED-REJECT ${e && e.message || e}`));
server.on('clientError', (err, socket) => { try { socket.destroy(); } catch (e) {} });

server.listen(PORT, '127.0.0.1', () => log(`LISTEN 127.0.0.1:${PORT}`));

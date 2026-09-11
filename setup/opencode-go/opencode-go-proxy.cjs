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
    const sid = req.headers['x-opencode-session'] || crypto.randomUUID();
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
    const proxied = https.request(opts, (pres) => {
      log(`RESP ${req.url} -> ${pres.statusCode}`);
      res.writeHead(pres.statusCode, pres.headers);
      pres.pipe(res);
    });
    proxied.on('error', (e) => {
      log('PROXY-ERR ' + e.message);
      if (!res.headersSent) res.writeHead(502);
      res.end('proxy error: ' + e.message);
    });
    proxied.write(body);
    proxied.end();
  });
});
server.listen(PORT, '127.0.0.1', () => log(`LISTEN 127.0.0.1:${PORT}`));

// retry-proxy.cjs — универсальный локальный retry-прокси для Claude Code.
// Зачем: при обрыве связи / транзиентных ошибках API Claude Code получает ошибку
// и останавливается. Прокси ретраит запрос сам, с экспоненциальным бэкоффом,
// и клиент видит ошибку только если все попытки исчерпаны.
//
//   Claude Code → retry-proxy (127.0.0.1:$RP_PORT) → $RP_TARGET_URL
//
// Настройка (env):
//   RP_PORT        — порт (по умолчанию 1880)
//   RP_TARGET_URL  — базовый URL бэкенда, напр. https://dashscope.aliyuncs.com/apps/anthropic
//   RP_DELAYS      — задержки ретраев в секундах через запятую
//                    (по умолчанию "0,2,4,8,16,32,64,128,256" — суммарно ~8,5 мин,
//                    укладывается в API_TIMEOUT_MS=600000 у Claude Code)
//   RP_RETRY_STATUS — какие HTTP-статусы ретраить (по умолчанию "429,500,502,503,504")
//
// ГЛАВНОЕ ПРАВИЛО: прокси никогда не падает. Ошибки потоков глушатся,
// клиентское соединение закрывается — Claude Code переотправит запрос сам.
// Ретрай возможен только ДО отправки заголовков клиенту; если ответ уже
// стримится — не вмешиваемся.
const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.env.RP_PORT || 1880);
const TARGET = new URL(process.env.RP_TARGET_URL || 'https://dashscope.aliyuncs.com/apps/anthropic');
const DELAYS = (process.env.RP_DELAYS || '0,2,4,8,16,32,64,128,256').split(',').map(s => Number(s.trim()) * 1000);
const RETRY_STATUS = new Set((process.env.RP_RETRY_STATUS || '429,500,502,503,504').split(',').map(s => Number(s.trim())));
const LOG = process.env.RP_LOG || path.join(__dirname, 'retry-proxy.log');
const CONNECT_TIMEOUT_MS = 120000;

function log(msg) {
  try { fs.appendFileSync(LOG, `[${new Date().toISOString()}] ${msg}\n`); } catch (e) {}
}
try { if (fs.existsSync(LOG) && fs.statSync(LOG).size > 2 * 1024 * 1024) fs.truncateSync(LOG, 0); } catch (e) {}

function isRetryableErr(err) {
  const codes = ['ECONNRESET', 'EPIPE', 'ETIMEDOUT', 'ECONNREFUSED', 'ENOTFOUND',
    'EAI_AGAIN', 'ECONNABORTED', 'EHOSTUNREACH', 'ENETUNREACH', 'ENETDOWN', 'EHOSTDOWN'];
  return codes.includes(err.code) || /ConnectionRefused|socket hang up|network|timeout/i.test(err.message || '');
}
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

const server = http.createServer((req, res) => {
  // Health-probe: Claude Code (Bun) стучится на /api/hello — отвечаем 200.
  if (req.url === '/api/hello') {
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end('{"ok":true}');
    return;
  }
  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('error', () => { try { res.destroy(); } catch (e) {} });
  req.on('end', () => {
    const body = Buffer.concat(chunks);
    const headers = { ...req.headers };
    delete headers['host'];
    delete headers['content-length'];
    delete headers['connection'];

    let clientGone = false;
    res.on('close', () => { clientGone = true; });

    (async () => {
      for (let attempt = 0; ; attempt++) {
        if (clientGone) return;
        const result = await new Promise((resolve) => {
          const opts = {
            hostname: TARGET.hostname,
            port: TARGET.port || 443,
            path: TARGET.pathname.replace(/\/$/, '') + req.url,
            method: req.method,
            headers,
          };
          const upstream = https.request(opts, (pres) => resolve({ type: 'response', pres }));
          upstream.setTimeout(CONNECT_TIMEOUT_MS, () => {
            upstream.destroy(Object.assign(new Error('connect timeout'), { code: 'ETIMEDOUT' }));
          });
          upstream.on('error', (e) => resolve({ type: 'error', err: e }));
          upstream.end(body);
        });

        if (result.type === 'error') {
          const retryable = isRetryableErr(result.err);
          log(`ERR ${req.url} attempt=${attempt + 1} ${result.err.code || result.err.message}`);
          if (retryable && attempt < DELAYS.length && !clientGone) {
            await sleep(DELAYS[attempt]);
            continue;
          }
          if (!clientGone && !res.headersSent) {
            res.writeHead(502, { 'content-type': 'application/json' });
            res.end(JSON.stringify({ type: 'error', error: { type: 'proxy_error', message: String(result.err.message || result.err.code) } }));
          }
          return;
        }

        const pres = result.pres;
        if (RETRY_STATUS.has(pres.statusCode) && attempt < DELAYS.length && !clientGone) {
          log(`RETRY ${req.url} attempt=${attempt + 1} status=${pres.statusCode} delay=${DELAYS[attempt] / 1000}s`);
          pres.resume(); // сливаем тело, освобождаем сокет
          await sleep(DELAYS[attempt]);
          continue;
        }

        // Ответ отдаём клиенту; с этого момента ретраи невозможны.
        log(`OK ${req.url} -> ${pres.statusCode} (attempts=${attempt + 1})`);
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

server.listen(PORT, '127.0.0.1', () => log(`LISTEN 127.0.0.1:${PORT} -> ${TARGET.href} delays=[${DELAYS.map(d => d / 1000).join(',')}] retryStatus=[${[...RETRY_STATUS].join(',')}]`));

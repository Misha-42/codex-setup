# AgentRouter + OpenCode — Полная инструкция

> Дата настройки: 2026-08-25
> Прокси: agentrouter-proxy (npm)
> Провайдер: agentrouter.org

---

## 1. Что было сделано

### 1.1 Установка прокси
```powershell
npm install -g agentrouter-proxy
```

### 1.2 Запуск прокси
```powershell
node "$env:APPDATA\npm\node_modules\agentrouter-proxy\bin\cli.js"
```
Прокси слушает на `http://localhost:8318/v1`, проксирует запросы на `https://agentrouter.org`.

### 1.3 Добавление в автозапуск (Task Scheduler)
```powershell
$nodePath = (Get-Command node).Source
$cliScript = "$env:APPDATA\npm\node_modules\agentrouter-proxy\bin\cli.js"
$action = New-ScheduledTaskAction -Execute $nodePath -Argument "`"$cliScript`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
Register-ScheduledTask -TaskName "AgentRouter Proxy" -Action $action -Trigger $trigger -Settings $settings -Description "agentrouter-proxy on localhost:8318" -RunLevel Limited -Force
```

### 1.4 Конфиг opencode.json
Файл: `C:\Users\user\soda-ml-carbonation-control\opencode.json`

Добавлен провайдер `agentrouter`:
```json
"agentrouter": {
  "options": {
    "baseURL": "http://localhost:8318/v1",
    "apiKey": "sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1"
  },
  "models": {
    "deepseek-v4-flash": {"name": "DeepSeek V4 Flash"},
    "gpt-5.6-sol": {"name": "GPT 5.6 Sol"},
    "claude-opus-5": {"name": "Claude Opus 5"}
  }
}
```

---

## 2. Проблемы и решения

### Проблема 1: Порт 1880 — 401 Unauthorized
Изначально baseURL был `http://localhost:1880/v1`. Все запросы возвращали 401.
**Решение:** сменить порт на 8318 (стандартный для agentrouter-proxy).

### Проблема 2: `agentrouter-proxy` не найден как команда
`Start-Process -FilePath "agentrouter-proxy"` не работал — бинарник не в PATH.
**Решение:** запускать через `node "$env:APPDATA\npm\node_modules\agentrouter-proxy\bin\cli.js"`.

### Проблема 3: "sensitive words detected"
Некоторые запросы блокируются фильтром agentrouter.org (слова типа "capital of France" и т.п.).
**Решение:** не наша проблема — ограничение на стороне agentrouter.org.

---

## 3. Стоимость моделей

| Модель | Input $/1M tokens | Output $/1M tokens | Cache $/1M tokens | Множитель |
|--------|-------------------|--------------------|--------------------|-----------|
| claude-opus-5 | $6.00 | $30.00 | — | ×3, output ×5 |
| gpt-5.6-sol | $3.00 | $15.00 | $1.50 | ×1.5, output ×5, cache ×0.5 |
| deepseek-v4-flash | $2.00 | $6.00 | — | ×1, output ×3 |

**Лимит аккаунта:** $1 (hard limit).

---

## 4. Диагностика — если что-то сломалось

### 4.1 Проверить, что прокси запущен
```powershell
# Проверить порт
try { $tcp = [System.Net.Sockets.TcpClient]::new(); $tcp.Connect("localhost", 8318); "Port 8318 is OPEN"; $tcp.Close() } catch { "Port 8318 is CLOSED" }

# Проверить задачу в Task Scheduler
Get-ScheduledTask -TaskName "AgentRouter Proxy"
```

### 4.2 Запустить прокси вручную (если не стартанул)
```powershell
node "$env:APPDATA\npm\node_modules\agentrouter-proxy\bin\cli.js"
```

### 4.3 Проверить API-ключ
```powershell
curl -s http://localhost:8318/v1/models -H "Authorization: Bearer sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1"
```
Должен вернуть список моделей: claude-opus-5, gpt-5.6-sol, deepseek-v4-flash.

### 4.4 Тестовый запрос к каждой модели
```powershell
curl -s http://localhost:8318/v1/chat/completions -H "Authorization: Bearer sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1" -H "Content-Type: application/json" -d '{"model":"claude-opus-5","messages":[{"role":"user","content":"Hi"}],"max_tokens":20}'

curl -s http://localhost:8318/v1/chat/completions -H "Authorization: Bearer sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1" -H "Content-Type: application/json" -d '{"model":"gpt-5.6-sol","messages":[{"role":"user","content":"Hi"}],"max_tokens":20}'

curl -s http://localhost:8318/v1/chat/completions -H "Authorization: Bearer sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1" -H "Content-Type: application/json" -d '{"model":"deepseek-v4-flash","messages":[{"role":"user","content":"Hi"}],"max_tokens":20}'
```

### 4.5 Проверить расход
```powershell
curl -s http://localhost:8318/v1/dashboard/billing/usage -H "Authorization: Bearer sk-HlIpYS3z1x0HTg88Geu9C97B5PZfsWmkUbR5W1naqPoISVi1"
```

### 4.6 Перезапустить задачу (если прокси упал)
```powershell
Stop-ScheduledTask -TaskName "AgentRouter Proxy"
Start-ScheduledTask -TaskName "AgentRouter Proxy"
```

### 4.7 Удалить задачу (если нужно переустановить)
```powershell
Unregister-ScheduledTask -TaskName "AgentRouter Proxy" -Confirm:$false
```

---

## 5. Кэш

| Модель | Кэш | Заметки |
|--------|-----|---------|
| gpt-5.6-sol | ✓ Работает | cached_tokens виден в ответе, скидка ×0.5 |
| claude-opus-5 | ✗ Не замечен | cached_tokens = 0 |
| deepseek-v4-flash | ✗ Не замечен | cached_tokens = 0 |

---

## 6. Переключение моделей в opencode

В opencode использовать `/models` для переключения между:
- `agentrouter/claude-opus-5`
- `agentrouter/gpt-5.6-sol`
- `agentrouter/deepseek-v4-flash`

Или задать в конфиге:
```json
"model": "agentrouter/deepseek-v4-flash"
```

---

## 7. Контакты и ссылки

- Прокси: https://github.com/thecapt1917/agentrouter-proxy
- Провайдер: https://agentrouter.org
- Дашборд (цены, логи): https://agentrouter.org → Консоль

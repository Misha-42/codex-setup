# Инструкция: собрать Claude Code + Codex как на рабочей машине

Выполнять по порядку. Каждый шаг заканчивается проверкой — если проверка не прошла,
дальше идти нет смысла.

Инструкция для **агента или человека** на новой машине. Дополняет:
- `SETUP-INSTRUCTION.md` — установка Codex;
- `.claude\README-setup.md` — что где лежит в готовом Claude-профиле (читать после).

---

## Шаг 0. Предпосылки

| Компонент | Зачем | Проверка |
|---|---|---|
| Windows 10/11 | целевая ОС | — |
| PowerShell 7 (`pwsh`) | все скрипты, профили | `pwsh -v` |
| Git | клонирование репозиториев | `git --version` |
| Node.js 20+ | Claude Code, MCP-сервер safe-docx, прокси OpenCode Go | `node -v` |
| Python 3.13 | MCP-сервер word-ai | `python --version` |
| Windows Terminal | ярлыки `.vbs` открываются через `wt` | `wt -v` |

```powershell
foreach ($c in 'pwsh','git','node','python','wt') {
  $p = (Get-Command $c -ErrorAction SilentlyContinue).Source
  if ($p) { "OK   $c -> $p" } else { "НЕТ  $c" }
}
```

Если `wt` не найден — поставь Windows Terminal из Microsoft Store, иначе ярлыки
из шага 6 не запустятся.

---

## Шаг 1. Codex

Полностью по `SETUP-INSTRUCTION.md` (установка Codex, три ключа, `~\.codex`,
`bat-files\*` → `~\Desktop\Codex\`, `scripts\*` → `~\`). Не дублирую.

Кратко, если делать только Codex:

```powershell
powershell -ExecutionPolicy Bypass -c '$env:CODEX_NON_INTERACTIVE=1; irm https://chatgpt.com/codex/install.ps1 | iex'
New-Item -ItemType Directory -Path ~\.codex -Force
Copy-Item config\config.toml,config\dashscope.config.toml ~\.codex\ -Force
New-Item -ItemType Directory -Path ~\Desktop\Codex -Force
Copy-Item bat-files\* ~\Desktop\Codex\ -Force
Copy-Item scripts\* ~\ -Force
```

---

## Шаг 2. Claude Code

```powershell
npm install -g @anthropic-ai/claude-code
claude --version      # ожидается 2.1.x
```

---

## Шаг 3. Три профиля

Профили **изолированы**: у каждого свой каталог настроек, свои MCP-серверы и своя
модель. Ключевой механизм — переменная `CLAUDE_CONFIG_DIR`.

| Профиль | Каталог настроек | Чем запускается | Модель |
|---|---|---|---|
| DashScope (по умолчанию) | `~\.claude` | `claude`, алиасы `ccd` / `ds` | `qwen3-coder-480b-a35b-instruct` |
| AgentRouter | `~\.claude` + `--settings` | `claude-proxy.ps1`, алиасы `ccp` / `opus` | `claude-opus-5`, окно 60k |
| OpenCode Go | `~\.claude-go` | ярлык `.vbs` → `launch-go.ps1` | `deepseek-v4.1-flash` |

### 3.1. Профиль по умолчанию (DashScope)

```powershell
New-Item -ItemType Directory -Path ~\.claude -Force
Copy-Item setup\settings.json ~\.claude\settings.json -Force
```

`setup\settings.json` — шаблон с ключом DashScope. Он **отстаёт** от боевого файла:
в нём нет `statusLine`, `hooks` и `worktree`. Их надо донести вручную (шаг 5 и 7).

### 3.2. Профиль AgentRouter

```powershell
Copy-Item <приватные>\claude-proxy.ps1           ~\ -Force
Copy-Item <приватные>\claude\proxy-settings.json ~\.claude\ -Force
```

Читает `proxy-settings.json`: `localhost:8318`, модель `claude-opus-5`, effort `low`,
окно 60k через `CLAUDE_CODE_MAX_CONTEXT_TOKENS`. Если прокси не поднят — лаунчер сам
запускает `agentrouter-proxy --port 8318` и ждёт порт до 7 секунд.

### 3.3. Профиль OpenCode Go

```powershell
New-Item -ItemType Directory -Path ~\.claude-go -Force
Copy-Item setup\opencode-go\launch-go.ps1         ~\.claude-go\ -Force
Copy-Item setup\opencode-go\opencode-go-proxy.cjs ~\.claude-go\ -Force
Copy-Item <приватные>\claude-go\settings.json     ~\.claude-go\settings.json -Force
```

`launch-go.ps1` поднимает локальный прокси на 1889 (`opencode-go-proxy.cjs`), выставляет
`CLAUDE_CONFIG_DIR=~\.claude-go` и запускает:

```powershell
claude --model deepseek-v4.1-flash --effort low --setting-sources user --permission-mode bypassPermissions
```

Два флага здесь не косметика:

- `--setting-sources user` — чтобы настройки из `<cwd>\.claude\settings.json` (DashScope)
  не перебивали профиль Go;
- `--permission-mode bypassPermissions` — **обязателен**. Без него сессия стартует в режиме
  `auto`, и классификатор auto-режима режет рутинные команды. Проверено 12.09.2026:
  ключ `permissions.defaultMode` в `settings.json` не доезжает до старта сессии, флаг доезжает.

### Проверка профилей

```powershell
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-go"
claude mcp list          # должно отработать без ошибок
$env:CLAUDE_CONFIG_DIR = $null
```

---

## Шаг 4. MCP-серверы

**Не копировать `~\.claude.json` и `~\.claude-go\.claude.json` с другой машины** — там
история сессий и учётные данные, и пути в них жёстко привязаны к имени пользователя.
Регистрировать заново, командами ниже.

### 4.1. safe-docx

```powershell
npm install -g @usejunior/safe-docx
$sd = "$(npm root -g)\@usejunior\safe-docx\bin\safe-docx.js"
Test-Path $sd      # должно быть True
```

### 4.2. word-ai

Репозиторий-источник: `Misha-42/word-ai`, ветка `fix/stdio-utf8`.

```powershell
Set-Location ~\Documents\GitHub
git clone https://github.com/Misha-42/word-ai.git
Set-Location word-ai
git checkout fix/stdio-utf8
python -m venv .venv
.\.venv\Scripts\pip install -e .
```

### 4.3. Регистрация в обоих профилях

MCP-серверы хранятся **отдельно** от настроек, и у каждого профиля свой файл.
Регистрация в одном не видна из другого — делать обе.

```powershell
$sd  = "$(npm root -g)\@usejunior\safe-docx\bin\safe-docx.js"
$wai = "$env:USERPROFILE\Documents\GitHub\word-ai"
$sdJson  = '{"command":"node","args":["' + ($sd -replace '\\','\\\\') + '","serve"]}'
$waiJson = '{"command":"' + ($wai -replace '\\','\\\\') + '\\.venv\\Scripts\\word-ai-mcp.exe","args":["--root","' + ($wai -replace '\\','\\\\') + '","--allow-root","' + ($env:USERPROFILE -replace '\\','\\\\') + '\\Documents"]}'

# профиль по умолчанию
$env:CLAUDE_CONFIG_DIR = $null
claude mcp add-json safe-docx $sdJson  --scope user
claude mcp add-json word-ai   $waiJson --scope user

# профиль OpenCode Go
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-go"
claude mcp add-json safe-docx $sdJson  --scope user
claude mcp add-json word-ai   $waiJson --scope user

$env:CLAUDE_CONFIG_DIR = $null
```

Флаг `--scope user` обязателен. Без него сервер уедет в project scope и будет виден
только из одной папки.

**Грабли:** `claude mcp add word-ai ... -- --root ...` не работает — CLI разбирает
`--root` как свой собственный флаг и падает с `unknown option`. Только `add-json`
с готовой JSON-строкой.

### 4.4. Проверка

```powershell
$env:CLAUDE_CONFIG_DIR = $null
claude mcp list
```

Ожидается по две строки `✔ Connected` — из **любого** каталога. Если сервер виден
только из папки репозитория — значит он лёг в project scope, переделать с `--scope user`.

### 4.5. Движок word-ai (необязательно, но рекомендуется)

По умолчанию word-ai работает на Python-движке. Есть нативный .NET-бэкенд — он быстрее
и **не требует .NET SDK**.

```powershell
$wai = "$env:USERPROFILE\Documents\GitHub\word-ai"
New-Item -ItemType Directory -Path "$wai\dist\native\win-x64" -Force
```

Взять `WordAi.OpenXml.exe` из релизного `.mcpb` репозитория и положить туда.
Селектор движка ищет его в `dist/native/<rid>/`, раньше чем `dotnet`; путь `dist/`
уже в `.gitignore`, так что в git он не попадёт.

Проверка:

```powershell
Set-Location $wai
.\.venv\Scripts\python.exe -c "import sys; sys.path.insert(0,'.'); from word_ai_mcp.openxml_engine import dotnet_status; print(dotnet_status('.'))"
```

Ожидается `'available': True, 'mode': 'native'`.

**Известная дыра:** `scripts\run_dotnet_regression.py` хардкодит `dotnet run` и не
обращается к селектору движка. Без .NET SDK 8.0.128 падает с
`A compatible .NET SDK was not found`. Сам движок при этом рабочий — проверяется через
`word_ai_mcp.openxml_engine` напрямую.

---

## Шаг 5. Statusline

```powershell
Copy-Item <приватные>\claude\statusline.ps1 ~\.claude\ -Force
```

Затем в `~\.claude\settings.json` добавить:

```json
"statusLine": {
  "type": "command",
  "command": "pwsh -NoProfile -NonInteractive -ExecutionPolicy Bypass -File \"C:\\Users\\<USER>\\.claude\\statusline.ps1\"",
  "padding": 0,
  "refreshInterval": 5
}
```

**Путь в `command` абсолютный, имя пользователя заменить.** Скрипт читает stdin как UTF-8
явно, поэтому кириллица в `cwd` не бьётся независимо от локали.

Вид строки:

```
Opus 5 max | ██░░░░░░░░ 26% 52.3k/200.0k | $0.8702 | +317/-97 | МУС
```

### Проверка без запуска Claude

```powershell
'{"model":{"display_name":"Test"},"workspace":{"current_dir":"C:\Users"},"context_window":{"used_percentage":26,"context_window_size":200000},"cost":{"total_cost_usd":0.87}}' | pwsh -NoProfile -File ~\.claude\statusline.ps1
```

Ожидается непустая строка и `exit=0`.

**Профиль Go — отдельный файл.** `--setting-sources user` читает
`~\.claude-go\settings.json`, а не `~\.claude\settings.json`. В `statusLine` нужно
прописать в **обоих**, иначе в окне Go бара не будет.

---

## Шаг 6. Ярлыки на рабочем столе

```powershell
# Claude: .vbs по одной модели на файл
Copy-Item "*.vbs" "$env:USERPROFILE\Desktop\Claude\Свежие (последние 3 месяца)\" -Force
```

Ярлык Go-профиля — `DeepSeek V4.1 Flash (OpenCode Go).vbs`, цепочка:

```
.vbs → wt -w 0 nt -d %USERPROFILE% --title "Claude - DeepSeek V4.1 Flash (OpenCode Go)"
         pwsh -NoExit -ExecutionPolicy Bypass -File %USERPROFILE%\.claude-go\launch-go.ps1
     → launch-go.ps1 → прокси 1889 → claude
```

Пути в `.vbs` переносимые (`%USERPROFILE%`), жёстких `C:\Users\user` быть не должно.

---

## Шаг 7. Хуки (необязательно)

В боевом `~\.claude\settings.json` есть `hooks`, которых нет в шаблоне:
`Stop` → звуковой сигнал, `PreCompact` → `compact_context.ps1` из репозитория
`soda-ml-carbonation-control`. Без этого репозитория хук будет падать — либо скопировать
репозиторий, либо убрать `PreCompact` из настроек.

---

## Чего в этом репозитории ещё нет

Инструкция выше рабочая, но часть файлов лежит **только на рабочей машине** и
переносится вручную. Отмечены `<приватные>` в шагах 3.2, 3.3, 5, 6:

| Файл | Куда | Содержит |
|---|---|---|
| `.claude\settings.json` | `~\.claude\` | ключ DashScope (шаблон в `setup\` отстал) |
| `.claude\settings.local.json` | `~\.claude\` | локальный allow-список |
| `.claude\aliases.ps1` | `~\.claude\` | алиасы `ccd`, `ccp`, `ccstat` |
| `.claude\launcher.ps1` | `~\.claude\` | меню запуска |
| `.claude\statusline.ps1` | `~\.claude\` | сам статус-бар |
| `.claude\proxy-settings.json` | `~\.claude\` | AgentRouter-профиль |
| `.claude\req-logger.ps1` | `~\.claude\` | отладка запросов |
| `.claude-go\settings.json` | `~\.claude-go\` | env профиля Go, `statusLine`, `allow` |
| `claude-proxy.ps1` | `~\` | лаунчер AgentRouter |
| `.vbs` с рабочего стола | `Desktop\Claude\` | ярлыки моделей |

Сложить их на рабочей машине в одну папку — она и есть `<приватные>` из шагов 3–6.
Структура повторяет целевые каталоги:

    <приватные>\
      claude-proxy.ps1
      claude\
        settings.json
        settings.local.json
        aliases.ps1
        launcher.ps1
        statusline.ps1
        proxy-settings.json
        req-logger.ps1
      claude-go\
        settings.json
      Desktop-Claude\
        *.vbs

Пока их нет в репозитории, «клонировал и работает» не получится — эти файлы надо
перенести с рабочей машины руками.

---

## Проверка после установки

```powershell
Write-Host "=== Claude ==="
claude --version

Write-Host "=== MCP (профиль по умолчанию) ==="
$env:CLAUDE_CONFIG_DIR = $null
claude mcp list

Write-Host "=== MCP (профиль Go) ==="
$env:CLAUDE_CONFIG_DIR = "$env:USERPROFILE\.claude-go"
claude mcp list
$env:CLAUDE_CONFIG_DIR = $null

Write-Host "=== Конфиги ==="
foreach ($p in "$env:USERPROFILE\.claude\settings.json",
               "$env:USERPROFILE\.claude-go\settings.json",
               "$env:USERPROFILE\.claude\statusline.ps1",
               "$env:USERPROFILE\.claude-go\launch-go.ps1",
               "$env:USERPROFILE\.claude-go\opencode-go-proxy.cjs") {
  "{0,-60} {1}" -f $p, (Test-Path $p)
}

Write-Host "=== Движок word-ai ==="
& "$env:USERPROFILE\Documents\GitHub\word-ai\.venv\Scripts\python.exe" -c "import sys;sys.path.insert(0,r'$env:USERPROFILE\Documents\GitHub\word-ai');from word_ai_mcp.openxml_engine import dotnet_status;print(dotnet_status(r'$env:USERPROFILE\Documents\GitHub\word-ai'))"
```

---

## Решение проблем

**Сессия спрашивает разрешения на каждую команду.**
Профиль стартовал в режиме `auto`. Проверить: отказ подписан
`denied by the Claude Code auto mode classifier`. Лечится флагом
`--permission-mode bypassPermissions` в лаунчере (шаг 3.3) и перезапуском сессии —
на уже запущенную сессию правка настроек не действует.

Посмотреть действующие правила классификатора:

```powershell
claude auto-mode config      # действующие
claude auto-mode defaults    # исходные
claude auto-mode critique    # разбор своих правил
```

Жёстко запрещено только `Data Exfiltration` (`hard_deny`, одно правило);
остальные 70 — `soft_deny` и настраиваются.

**MCP-сервер виден только из одной папки.**
Зарегистрирован в project scope. Переделать с `--scope user` (шаг 4.3).

**Статус-бара нет в окне Go-профиля.**
`statusLine` прописан только в `~\.claude\settings.json`. Профиль Go читает
`~\.claude-go\settings.json` — добавить туда (шаг 5).

**Кириллица в MCP-запросах возвращает пустой результат.**
Локаль процесса отдаёт cp1251, а MCP требует UTF-8. В `word_ai_mcp\server.py` это
лечится функцией `configure_stdio_utf8()`; ветка `fix/stdio-utf8`. Переменные
`PYTHONUTF8` / `PYTHONIOENCODING` для PyInstaller-сборки **не помогают**.

**`claude mcp add ... -- --root` падает с `unknown option`.**
Использовать `claude mcp add-json` (шаг 4.3).

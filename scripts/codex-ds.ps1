# codex-ds.ps1 — Codex на DashScope с автопереключением моделей по квоте.
#
# ВАРИАНТЫ ЗАПУСКА:
#   codex-ds                          -> интерактивный Codex на самой дешёвой живой модели
#   codex-ds "задача"                 -> одноразовая задача на самой дешёвой живой модели
#   codex-ds -PromptFile task.txt     -> промпт из UTF-8 файла (кириллица без искажений)
#   codex-ds -Batch tasks.txt [-OutDir папка] -> очередь задач (по строке, # — комментарий),
#                              результат каждой в out\NNN.txt, автопереключение моделей
#   codex-ds -Batch tasks.txt -Manifest  -> + ЯДРО кэш-манифеста (правила экономии токенов)
#                              в начало каждой задачи (из templates\00-cache-manifest.md)
#   codex-ds -Status                  -> сколько осталось у каждой модели
#   codex-ds -Model <id> "задача"     -> принудительно конкретная модель
#   codex-ds -SetDefault              -> обновить дефолт config.toml на самую дешёвую живую
#
# Логика: модели берутся по порядку от дешёвых к дорогим ($MODEL_ORDER).
# Расход копится в ~/.codex/dashscope-quota.json (парсинг usage из --json).
# При 403 (квота кончилась) модель помечается выгоревшей и берётся следующая.
# Если модель не поддерживает агентный формат (404/not found) — пропускается в этом запуске.
# Порог $LIMIT (900K) оставляет запас на неточность учёта.
# Дефолт config.toml всегда указывает на самую дешёвую живую модель.

param(
    [string]$Prompt,
    [string]$PromptFile,
    [string]$Model,
    [string]$Batch,
    [string]$OutDir,
    [switch]$Status,
    [switch]$Reset,
    [switch]$SetDefault,
    [switch]$Doctor,
    [switch]$Json,
    [switch]$Manifest
)

$ErrorActionPreference = 'Stop'
$StateFile = Join-Path $HOME '.codex\dashscope-quota.json'
$ConfigFile = Join-Path $HOME '.codex\config.toml'
$BASE_URL = 'https://ws-f6ebsbasa40o11u5.ap-southeast-1.maas.aliyuncs.com/compatible-mode/v1'
$QUOTA = 1000000
$LIMIT = 900000
# Ротация: все чат-модели рабочего пространства, от дешёвых к дорогим.
# Каждая имеет собственную бесплатную квоту 1M токенов (до 2026-11-18).
$MODEL_ORDER = @(
    # --- дешёвые (flash / малые) ---
    'deepseek-v4-flash',
    'qwen3.7-flash',
    'qwen3.6-flash',
    'qwen3.5-flash',
    'qwen-flash',
    'qwen-turbo',
    'qwen3-coder-flash',
    'qwen3.8-27b',
    'qwen3.6-27b',
    'qwen3.5-27b',
    'qwen3-8b',
    'qwen3-14b',
    'qwen3-32b',
    # --- средние (plus) ---
    'qwen3.7-plus',
    'qwen3.6-plus',
    'qwen3.5-plus',
    'qwen-plus',
    'qwen3-30b-a3b',
    'qwen3.5-35b-a3b',
    'qwen3.6-35b-a3b',
    'qwen3-coder-plus',
    'deepseek-v3.2',
    # --- умные (pro / max) ---
    'deepseek-v4-pro',
    'qwen3.7-max',
    'qwen3.5-122b-a10b',
    'qwen3-235b-a22b',
    'qwen3-coder-next',
    # --- флагманы (в самую последнюю очередь) ---
    'deepseek-v4-pro-0813',
    'qwen3.8-max',
    'ZHIPU/GLM-5.3',
    'glm-5.2',
    'kimi-k2.7-code',
    'qwen3.5-397b-a17b'
)

# --- Ключ: из сессии или из реестра (setx) ---
if (-not $env:DASHSCOPE_API_KEY) {
    $env:DASHSCOPE_API_KEY = [Environment]::GetEnvironmentVariable('DASHSCOPE_API_KEY', 'User')
}
if (-not $env:DASHSCOPE_API_KEY) {
    Write-Error "DASHSCOPE_API_KEY не задан (setx DASHSCOPE_API_KEY ...)"
}

# --- Кэш-прокси (24h retention): автозапуск, если порт 1888 мёртв.
#     Обёртка ходит на 127.0.0.1:1888 через -c; Desktop codex — напрямую. ---
$ProxyScript = Join-Path $PSScriptRoot 'dashscope-cache-proxy.cjs'
function Test-Port([int]$port) {
    try {
        $c = New-Object System.Net.Sockets.TcpClient
        $iar = $c.BeginConnect('127.0.0.1', $port, $null, $null)
        if (-not $iar.AsyncWaitHandle.WaitOne(1000)) { $c.Close(); return $false }
        $c.EndConnect($iar); $c.Close(); return $true
    } catch { return $false }
}
function Ensure-Proxy {
    if (Test-Port 1888) { return $true }
    if (-not (Test-Path $ProxyScript)) { return $false }
    Start-Process -FilePath 'node' -ArgumentList $ProxyScript -WindowStyle Hidden
    $deadline = [DateTime]::Now.AddSeconds(5)
    while (-not (Test-Port 1888) -and [DateTime]::Now -lt $deadline) { Start-Sleep -Milliseconds 300 }
    return (Test-Port 1888)
}
$PROXY_OVERRIDE = 'model_providers.dashscope.base_url="http://127.0.0.1:1888"'

# --- Кэш-манифест: ЯДРО из codex-stack\templates\00-cache-manifest.md (флаг -Manifest).
#     Правила экономии токенов (novasapiens/arXiv) в начало каждой задачи. ---
function Get-ManifestCore {
    $candidates = @(
        (Join-Path $PSScriptRoot 'codex-stack\templates\00-cache-manifest.md'),
        (Join-Path $HOME 'codex-stack\templates\00-cache-manifest.md'),
        (Join-Path $PSScriptRoot 'templates\00-cache-manifest.md')
    )
    $file = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $file) { return $null }
    $lines = Get-Content $file -Encoding UTF8
    $i = [Array]::IndexOf($lines, '## ЯДРО (вставь этот блок в начало промпта)')
    if ($i -lt 0) { $i = [Array]::IndexOf($lines, '## ЯДРО') }
    if ($i -lt 0) { return $null }
    $core = @()
    for ($j = $i + 1; $j -lt $lines.Count; $j++) {
        if ($lines[$j].StartsWith('## ')) { break }
        if ($lines[$j].Trim() -eq '```') { continue }
        $core += $lines[$j]
    }
    return (($core -join "`n").Trim())
}

# --- State-файл ---
function Get-State([switch]$SkipFetch) {
    $s = $null
    if (Test-Path $StateFile) {
        try {
            $s = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($null -eq $s.models) { $s = $null }
        } catch {
            Write-Host "    state-файл повреждён — пересоздаю учёт." -ForegroundColor Yellow
            $s = $null
        }
    }
    if ($null -eq $s) {
        $s = [pscustomobject]@{
            quota = $QUOTA
            limit = $LIMIT
            models = @()
        }
    }
    foreach ($m in $s.models) {
        if ($null -eq $m.skip) { Add-Member -InputObject $m -NotePropertyName 'skip' -NotePropertyValue $false -Force }
    }
    if ($SkipFetch) { return $s }   # -Status / -Reset: без обращения к API
    # ВСЕ модели рабочего пространства из API — используем максимум.
    # Несовместимые (картинки/аудио/эмбеддинги) отсеются сами при первой попытке.
    $apiIds = @()
    $fullList = $false
    try {
        $r = Invoke-RestMethod -Uri "$BASE_URL/models" -Headers @{ Authorization = "Bearer $env:DASHSCOPE_API_KEY" } -TimeoutSec 15
        $apiIds = @($r.data | ForEach-Object { $_.id })
        $fullList = ($null -ne $r.has_more) -and (-not $r.has_more)
    } catch { }
    if ($apiIds.Count -gt 0) {
        # Слияние ПОД ЛОКОМ: параллельный процесс не потеряет свои изменения,
        # а каталог DashScope живой — лишние модели сами отсеются при следующем фетче.
        $s = Update-State { param($st) Merge-Models $st $MODEL_ORDER $apiIds $fullList }
    }
    return $s
}
# --- Атомарная запись: tmp + переименование (читатель видит старый или новый файл, не обрывок) ---
function Save-State($s) {
    $s | ConvertTo-Json -Depth 5 | Set-Content "$StateFile.tmp" -Encoding UTF8
    Move-Item -Force "$StateFile.tmp" $StateFile
}
# --- Лок учёта: параллельные окна не теряют расход. Ждём до 60 c; лок старше 5 мин забираем (процесс умер) ---
$LockFile = Join-Path $HOME '.codex\dashscope-quota.lock'
function Lock-State {
    $deadline = [DateTime]::Now.AddSeconds(60)
    while ($true) {
        if (Test-Path $LockFile) {
            $stale = ([DateTime]::Now - (Get-Item $LockFile).LastWriteTime).TotalSeconds -gt 300
            if ($stale) { Remove-Item $LockFile -Force -ErrorAction SilentlyContinue; continue }
            if ([DateTime]::Now -gt $deadline) { return $false }
            Start-Sleep -Milliseconds 200
            continue
        }
        try {
            # New-Item без -Force НЕ перезаписывает существующий файл — атомарное создание.
            # Два процесса не смогут взять лок одновременно (второй уйдёт в ожидание).
            New-Item -ItemType File $LockFile -ErrorAction Stop | Out-Null
            Set-Content $LockFile ("PID=" + $PID) -Encoding ASCII
            return $true
        } catch {
            if ([DateTime]::Now -gt $deadline) { return $false }
            Start-Sleep -Milliseconds 200
        }
    }
}
function Unlock-State {
    if (Test-Path $LockFile) {
        try {
            if ((Get-Content $LockFile -Raw) -match 'PID=(\d+)' -and [int]$matches[1] -eq $PID) {
                Remove-Item $LockFile -Force
            }
        } catch {}
    }
}
# --- Единственный путь записи учёта: лок → свежий state → изменения → атомарно сохранить.
#     Дельты применяются к самому свежему состоянию, потерянных обновлений не бывает. ---
function Update-State([scriptblock]$Apply) {
    if (-not (Lock-State)) {
        Write-Host "    ⚠ Лок учёта занят 60 c — применяю к последнему известному state." -ForegroundColor Yellow
    }
    try {
        $fresh = Get-State -SkipFetch
        # | Out-Null: вывод скриптблока (например, Merge-Models или Add-Member)
        # не должен попасть в поток функции — иначе $s = Update-State {...}
        # соберёт массив из двух state-объектов
        & $Apply $fresh | Out-Null
        Save-State $fresh
        return $fresh
    } finally {
        Unlock-State
    }
}
# --- Слияние списка моделей со state (вызывается ТОЛЬКО под локом из Update-State) ---
function Merge-Models($st, $order, $apiIds, $fullList) {
    foreach ($id in $order) {
        if (-not ($st.models | Where-Object { $_.id -eq $id })) {
            $st.models += [pscustomobject]@{ id = $id; used = 0; skip = $false }
        }
    }
    foreach ($id in $apiIds) {
        if (-not ($st.models | Where-Object { $_.id -eq $id })) {
            $st.models += [pscustomobject]@{ id = $id; used = 0; skip = $false }
        }
    }
    # Чистка ТОЛЬКО при полном ответе API (has_more=false) — иначе сотрём учёт
    if ($apiIds.Count -gt 0 -and $fullList) {
        $st.models = @($st.models | Where-Object { $_.id -in $apiIds })
    }
    # Порядок: известные по $MODEL_ORDER, остальные — в конец (как вернул API)
    $byIdx = @{}
    for ($i = 0; $i -lt $order.Count; $i++) { $byIdx[$order[$i]] = $i }
    $st.models = @($st.models | Sort-Object { if ($byIdx.ContainsKey([string]$_.id)) { $byIdx[[string]$_.id] } else { 1000 } })
    return $st
}
function Get-Model($s, $id) {
    $s.models | Where-Object { $_.id -eq $id } | Select-Object -First 1
}
function Get-CheapestLive($s) {
    $s.models | Where-Object { $_.used -lt $s.limit -and -not $_.skip } | Select-Object -First 1
}
function Show-Status {
    $s = Get-State -SkipFetch
    $w = [math]::Max(30, ($s.models | ForEach-Object { $_.id.Length } | Measure-Object -Maximum).Maximum) + 2
    "{0,-$w} {1,11:N0} {2,12:N0}  {3}" -f 'Модель', 'Использовано', 'Осталось', 'Статус'
    "-" * ($w + 40)
    foreach ($m in $s.models) {
        $remaining = $s.quota - $m.used
        $status = if ($m.skip) { 'пропущена' }
                  elseif ($m.used -ge $s.limit) { 'ВЫГОРЕЛА' }
                  elseif ($m.used -gt 0) { 'в работе' }
                  else { 'не тронута' }
        "{0,-$w} {1,11:N0} {2,12:N0}  {3}" -f $m.id, $m.used, $remaining, $status
    }
    $live = Get-CheapestLive $s
    if ($live) { "`nСейчас дефолт: $($live.id)" } else { "`nВсе модели выгорели!" }
}
# --- Обновить строку `model`/`model_provider` в config.toml ---
function Set-DefaultModel($mid) {
    if (-not (Test-Path $ConfigFile)) {
        Write-Error "config.toml не найден: $ConfigFile — запустите codex хотя бы раз."
    }
    $cfg = Get-Content $ConfigFile -Raw -Encoding UTF8
    // Read current model from config
    $curMatch = [regex]::Match($cfg, '(?m)^model\s*=\s*"([^"]*)"')
    $curModel = ''
    if ($curMatch.Success) {
        $curModel = $curMatch.Groups[1].Value
    }

    // Если модель уже та же -- не пишем (фикс дергающейся строки)
    if ($curModel -eq $mid) {
        Write-Host "    Default already set - skipping." -ForegroundColor DarkGray
        return
    }

    if (-not (Test-Path "$ConfigFile.bak-last")) { Copy-Item $ConfigFile "$ConfigFile.bak-last" }
    # Есть ли строка model ВООБЩЕ (а не 'замена изменила текст':
    # если модель уже та же, замена не меняет содержимое — и это НЕ значит, что строки нет)
    $hasModel = [regex]::IsMatch($cfg, '(?m)^model\s*=')
    # Обрабатываем и двойные, и одинарные кавычки (валидный TOML)
    $cfg2 = [regex]::Replace($cfg, '(?m)^model\s*=\s*("[^"]*"|''[^'']*'')', "model = `"$mid`"")
    $cfg2 = [regex]::Replace($cfg2, '(?m)^model_provider\s*=\s*("[^"]*"|''[^'']*'')', 'model_provider = "dashscope"')
    if (-not $hasModel) {
        # Строки model нет — добавляем
        $cfg2 = $cfg.TrimEnd() + "`n`nmodel = `"$mid`"`nmodel_provider = `"dashscope`""
    }
    Set-Content $ConfigFile $cfg2 -Encoding UTF8 -NoNewline
    Write-Host "    Дефолт config.toml -> $mid" -ForegroundColor Cyan
}

# --- Доктор: самодиагностика (для ручной проверки и для Codex-ремонтника) ---
function Show-Doctor {
    $script:okC = 0; $script:badC = 0
    function Chk($name, $cond, $hint = '') {
        if ($cond) { Write-Host ("  [OK]   " + $name) -ForegroundColor Green; $script:okC++ }
        else { Write-Host ("  [FAIL] " + $name + ($(if ($hint) { ' — ' + $hint } else { '' }))) -ForegroundColor Red; $script:badC++ }
    }
    $hasCodex = $null -ne (Get-Command codex -ErrorAction SilentlyContinue)
    $hasKey = -not [string]::IsNullOrEmpty($env:DASHSCOPE_API_KEY)
    $stateOk = $false; $stateCount = 0
    try { $st = Get-Content $StateFile -Raw -Encoding UTF8 | ConvertFrom-Json; $stateOk = $null -ne $st.models; $stateCount = @($st.models).Count } catch {}
    $cfgOk = $false; $cfgModel = ''; $cwOk = $false; $cwVal = ''
    try {
        $cfg = Get-Content $ConfigFile -Raw -Encoding UTF8
        $cfgOk = $cfg -match '(?m)^model\s*='
        if ($cfg -match '(?m)^model\s*=\s*"([^"]+)"') { $cfgModel = $matches[1] }
        $cwOk = $cfg -match '(?m)^model_context_window\s*=\s*(\d+)'
        if ($cwOk) { $cwVal = $matches[1] }
    } catch {}
    $bomOk = $true
    foreach ($f in @($PSCommandPath, (Join-Path $HOME 'dashboard.ps1'))) {
        if (Test-Path $f) {
            $bytes = [System.IO.File]::ReadAllBytes($f)
            if (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) { $bomOk = $false }
        }
    }
    $apiOk = $false; $apiCount = 0
    try {
        $r = Invoke-RestMethod -Uri "$BASE_URL/models" -Headers @{ Authorization = "Bearer $env:DASHSCOPE_API_KEY" } -TimeoutSec 15
        $apiOk = $r.data.Count -gt 0; $apiCount = $r.data.Count
    } catch {}
    $profOk = Test-Path (Join-Path $HOME '.codex\dashscope.config.toml')
    $hdrOk = $false
    try {
        $prof = Get-Content (Join-Path $HOME '.codex\dashscope.config.toml') -Raw -Encoding UTF8
        $hdrOk = $prof -match 'x-dashscope-session-cache'
    } catch {}
    Chk 'codex доступен' $hasCodex
    Chk 'ключ DashScope задан' $hasKey 'setx DASHSCOPE_API_KEY ...'
    Chk 'API DashScope отвечает' $apiOk "моделей: $apiCount"
    Chk 'state-файл валиден' $stateOk "моделей: $stateCount"
    Chk 'config.toml: строка model есть' $cfgOk "сейчас: $cfgModel"
    Chk 'config.toml: context window (64K)' $cwOk "добавьте model_context_window = 65536 (сейчас: $cwVal)"
    Chk 'скрипты в UTF-8 c BOM' $bomOk 'пересохранить через Set-Content -Encoding utf8BOM'
    Chk 'профиль dashscope.config.toml' $profOk
    Chk 'профиль: заголовок session-cache' $hdrOk 'добавьте http_headers = { x-dashscope-session-cache = "enable" }'
    $pxOk = Test-Port 1888
    Chk 'кэш-прокси 24h (порт 1888)' $pxOk 'запустите: node C:\Users\user\dashscope-cache-proxy.cjs (обёртка делает это сама)'
    Write-Host ("`nИтого: OK=" + $script:okC + "  FAIL=" + $script:badC) -ForegroundColor $(if ($script:badC -gt 0) { 'Yellow' } else { 'Green' })
}

if ($Doctor) {
    Show-Doctor
    exit 0
}

if ($Reset) {
    $s = Update-State { param($st)
        foreach ($m in $st.models) {
            $m.used = 0
            if ($m.skip) { Add-Member -InputObject $m -NotePropertyName 'skip' -NotePropertyValue $false -Force }
        }
    }
    "Учёт обнулён (включая пометки 'пропущена')."
    exit 0
}
if ($Status) {
    Show-Status
    exit 0
}
if ($SetDefault) {
    $s = Get-State
    $live = Get-CheapestLive $s
    if (-not $live) { Write-Error "Все модели выгорели. -Reset или консоль DashScope." }
    Set-DefaultModel $live.id
    exit 0
}

# --- ИНТЕРАКТИВ: без промпта — обновляем дефолт и запускаем codex ---
# (не перехватываем -Batch: у него свой путь)
if (-not $Prompt -and -not $PromptFile -and -not $Batch) {
    $s = Get-State
    $live = Get-CheapestLive $s
    if (-not $live) { Write-Error "Все модели выгорели. -Reset или консоль DashScope." }
    Set-DefaultModel $live.id
    if (-not (Ensure-Proxy)) { Write-Host "    ⚠ Кэш-прокси не запустился — работаю напрямую (без 24h)." -ForegroundColor Yellow }
    Write-Host "Запускаю Codex на $($live.id) ... (Esc — выйти, /exit)" -ForegroundColor Green
    & codex -c $PROXY_OVERRIDE
    exit $LASTEXITCODE
}

# --- Запуск codex exec на ОДНОЙ модели; результат возвращается, state НЕ трогается ---
function Invoke-CodexExec($mid, $Prompt) {
    $res = [pscustomobject]@{ Exit = 1; Raw = ''; Used = 0; Cached = 0; Msg = @(); Burned = $false; Skipped = $false; TimedOut = $false }
    # Запуск с таймаутом 15 мин — зависшая модель не блокирует ротацию.
    # Длинный промпт (>8К символов) или начинающийся с '-' подаём через stdin.
    if ($null -ne (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue)) {
        $job = Start-ThreadJob -ScriptBlock {
            param($jm, $jp, $jk, $jov)
            $env:DASHSCOPE_API_KEY = $jk
            if ($jp.Length -gt 8000 -or $jp.StartsWith('-')) {
                $out = $jp | & codex exec --profile dashscope -m $jm --skip-git-repo-check --json -c $jov - 2>&1
            } else {
                $out = & codex exec --profile dashscope -m $jm --skip-git-repo-check --json -c $jov $jp 2>&1
            }
            [pscustomobject]@{ Exit = $LASTEXITCODE; Out = $out }
        } -ArgumentList $mid, $Prompt, $env:DASHSCOPE_API_KEY, $PROXY_OVERRIDE
        $done = Wait-Job $job -Timeout 900
        if (-not $done) {
            Stop-Job $job -Force; Remove-Job $job -Force
            $res.TimedOut = $true
            return $res
        }
        $jr = Receive-Job $job | Select-Object -First 1
        Remove-Job $job -Force
        $res.Exit = $jr.Exit
        $res.Raw = ($jr.Out | Out-String)
    } else {
        # Запасной путь (нет ThreadJob — например, Windows PowerShell 5.1)
        $res.Raw = (& codex exec --profile dashscope -m $mid --skip-git-repo-check --json -c $PROXY_OVERRIDE $Prompt 2>&1 | Out-String)
        $res.Exit = $LASTEXITCODE
    }
    foreach ($line in ($res.Raw -split "`n")) {
        $line = $line.Trim()
        if (-not $line.StartsWith('{')) { continue }
        try { $ev = $line | ConvertFrom-Json } catch { continue }
        if ($ev.type -eq 'turn.completed' -and $ev.usage) {
            $res.Used += [int]$ev.usage.input_tokens + [int]$ev.usage.output_tokens
            if ($ev.usage.cached_input_tokens) { $res.Cached += [int]$ev.usage.cached_input_tokens }
        }
        elseif ($ev.type -eq 'item.completed' -and $ev.item.type -eq 'agent_message') {
            $res.Msg += $ev.item.text
        }
    }
    # 403: точные фразы DashScope (insufficient_quota / Free quota exhausted) + исторические паттерны
    if ($res.Raw -match 'AllocationQuota|FreeTierOnly|insufficient_quota|Free quota exhausted|quota exhausted|HTTP[^\n]*403') { $res.Burned = $true }
    # Несовместимость: ТОЛЬКО по точным фразам DashScope (не по подстрокам вида 'not found')
    elseif ($res.Exit -ne 0 -and $res.Used -eq 0 -and $res.Raw -match 'Unsupported model|UnsupportedModel|ModelNotExist') { $res.Skipped = $true }
    return $res
}

# --- Прогнать задачу по кандидатам (ротация). Возвращает итог; запись учёта — под локом. ---
function Run-Task($Prompt, [string]$ForcedModel) {
    $script:anyBurned = $false
    if (-not (Ensure-Proxy)) {
        Write-Host "    ⚠ Кэш-прокси не запустился — работаю напрямую (без 24h)." -ForegroundColor Yellow
    }
    if ($ForcedModel) {
        $candidates = @($ForcedModel)
    } else {
        $s = Get-State
        $available = @($s.models | Where-Object { $_.used -lt $s.limit -and -not $_.skip })
        # Проверенно живые модели (прямой тест /v1/responses 2026-08-21) — пробуем первыми,
        # остальные отсеиваются при первом сбое (skip) и не тормозят ротацию.
        # deepseek-v4-flash и qwen3.7-flash сгорели (403 Free quota exhausted).
        $PREFER = @('qwen3-coder-flash', 'qwen-turbo', 'qwen-plus')
        $candidates = @($PREFER | Where-Object { $pid_ = $_; $available | Where-Object { $_.id -eq $pid_ } })
        $candidates += @($available | Where-Object { $candidates -notcontains $_.id } | ForEach-Object { $_.id })
        if ($candidates.Count -eq 0) {
            Write-Host "    ⚠ Все модели выгорели." -ForegroundColor Red
            return [pscustomobject]@{ Ok = $false; Used = 0; Msg = @(); Raw = ''; Model = ''; Exhausted = $true }
        }
    }
    foreach ($mid in $candidates) {
        $s = Get-State -SkipFetch
        $m = Get-Model $s $mid
        Write-Host "==> Модель: $mid (использовано $($m.used))" -ForegroundColor Cyan
        $r = Invoke-CodexExec $mid $Prompt
        if ($r.TimedOut) {
            Write-Host "    Таймаут 15 мин — модель $mid зависла, пропускаю." -ForegroundColor Red
            continue
        }
        # 403: квота кончилась → выгорела, пробуем следующую
        if ($r.Burned) {
            Write-Host "    Квота модели $mid исчерпана (403) — помечаю выгоревшей, пробую следующую." -ForegroundColor Yellow
            $s = Update-State { param($st) $mm = Get-Model $st $mid; if ($mm) { $mm.used = $st.quota } }
            $script:anyBurned = $true
            continue
        }
        if ($r.Exit -ne 0 -and $r.Used -eq 0) {
            # Детерминированная несовместимость — помечаем и больше не пробуем
            if ($r.Skipped) {
                Write-Host "    Модель $mid несовместима с агентным форматом — помечаю и больше не пробую." -ForegroundColor DarkGray
                $s = Update-State { param($st) $mm = Get-Model $st $mid; if ($mm) { Add-Member -InputObject $mm -NotePropertyName 'skip' -NotePropertyValue $true -Force } }
                continue
            }
            # Непредвиденная ошибка (сеть, сервер и т.п.) — стоп, чтобы не жечь модели подряд
            Write-Host "    Модель $mid не сработала (exit $($r.Exit)) — останавливаюсь." -ForegroundColor Red
            ($r.Raw -split "`n") | Select-Object -Last 3
            return [pscustomobject]@{ Ok = $false; Used = 0; Msg = @(); Raw = $r.Raw; Model = $mid; Exhausted = $false }
        }
        # Частичный сбой (токены потрачены, ответа нет) — учёт сохраняем, пробуем следующую
        if ($r.Exit -ne 0 -and $r.Used -gt 0) {
            Write-Host "    Модель $mid сбоит на середине (потрачено $($r.Used)) — пробую следующую." -ForegroundColor Yellow
            $s = Update-State { param($st) $mm = Get-Model $st $mid; if ($mm) { $mm.used += $r.Used } }
            continue
        }
        # Успех
        $s = Update-State { param($st) $mm = Get-Model $st $mid; if ($mm) { $mm.used += $r.Used } }
        $cacheNote = if ($r.Cached -gt 0) { ", из них из кэша: $($r.Cached) ($([math]::Round(100.0 * $r.Cached / [math]::Max($r.Used, 1)))%)" } else { '' }
        Write-Host "    [использовано: $($r.Used) токенов$cacheNote, всего по модели $((Get-Model $s $mid).used)]" -ForegroundColor DarkGray
        return [pscustomobject]@{ Ok = $true; Used = $r.Used; Msg = $r.Msg; Raw = $r.Raw; Model = $mid; Exhausted = $false }
    }
    Write-Host "    ⚠ Все кандидаты исчерпаны (квоты/несовместимость). Детали: codex-ds -Status" -ForegroundColor Red
    return [pscustomobject]@{ Ok = $false; Used = 0; Msg = @(); Raw = ''; Model = ''; Exhausted = $true }
}

# --- BATCH: очередь задач из файла (по строке, # — комментарий, пустые пропускаются) ---
if ($Batch) {
    if (-not (Test-Path $Batch)) { Write-Error "Файл задач не найден: $Batch" }
    $tasks = @(Get-Content $Batch -Encoding UTF8 |
        Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') } |
        ForEach-Object { $_.Trim() })
    if ($tasks.Count -eq 0) { Write-Error "В файле $Batch нет задач (пустые строки и # игнорируются)." }
    $manifestCore = $null
    if ($Manifest) {
        $manifestCore = Get-ManifestCore
        if ($manifestCore) { Write-Host "Кэш-манифест: ЯДРО ($($manifestCore.Split("`n").Count) строк) в начало каждой задачи." -ForegroundColor Green }
        else { Write-Host '⚠ -Manifest: файл 00-cache-manifest.md не найден — продолжаю без ядра.' -ForegroundColor Yellow }
    }
    if (-not $OutDir) { $OutDir = Join-Path $HOME ('.codex\batch-' + (Get-Date -Format 'yyyyMMdd-HHmmss')) }
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    Write-Host ("Batch: {0} задач -> {1}" -f $tasks.Count, $OutDir) -ForegroundColor Green
    $okN = 0; $failN = 0; $total = 0
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $n = '{0:D3}' -f ($i + 1)
        $preview = ($tasks[$i] -replace '\s+', ' ')
        if ($preview.Length -gt 70) { $preview = $preview.Substring(0, 70) + '…' }
        Write-Host ("  [{0}/{1}] {2}" -f $n, $tasks.Count, $preview) -ForegroundColor DarkCyan
        $taskPrompt = if ($manifestCore) { "$manifestCore`n`n$($tasks[$i])" } else { $tasks[$i] }
        $res = Run-Task $taskPrompt $Model
        if ($res.Exhausted) {
            Write-Host "    ⚠ Квоты исчерпаны — прерываю очередь." -ForegroundColor Red
            exit 2
        }
        $out = Join-Path $OutDir "$n.txt"
        if ($res.Ok) {
            $okN++; $total += $res.Used
            $res.Msg | Set-Content $out -Encoding UTF8
            Write-Host ("  [{0}/{1}] OK   {2,6} токенов  ({3})" -f $n, $tasks.Count, $res.Used, $res.Model) -ForegroundColor Green
        } else {
            $failN++
            "FAIL (exit без ответа)" | Set-Content $out -Encoding UTF8
            Write-Host ("  [{0}/{1}] FAIL ({2})" -f $n, $tasks.Count, $res.Model) -ForegroundColor Red
        }
    }
    Write-Host ("Batch завершён: OK={0}  FAIL={1}  потрачено {2} токенов.  Файлы: {3}" -f $okN, $failN, $total, $OutDir) -ForegroundColor Cyan
    if ($failN -gt 0) { exit 1 } else { exit 0 }
}

# --- Одноразовая задача (exec) ---
if ($PromptFile) {
    $Prompt = Get-Content $PromptFile -Raw -Encoding UTF8
}
if ($Manifest) {
    $manifestCore = Get-ManifestCore
    if ($manifestCore) { $Prompt = "$manifestCore`n`n$Prompt" }
    else { Write-Host '⚠ -Manifest: файл 00-cache-manifest.md не найден — продолжаю без ядра.' -ForegroundColor Yellow }
}
if (-not $Prompt) {
    Write-Error "Нет промпта: передайте текст, -PromptFile file.txt или запустите без аргументов (интерактив)."
}

$s = Get-State
if ($Model -and -not (Get-Model $s $Model)) {
    $s = Update-State { param($st) $st.models += [pscustomobject]@{ id = $Model; used = 0; skip = $false } }
}
$r = Run-Task $Prompt $Model
if ($r.Ok) {
    $r.Msg | ForEach-Object { Write-Output $_ }
    if ($Json) { Write-Output $r.Raw }
    exit 0
}
if ($r.Exhausted) { exit 2 }
exit 1

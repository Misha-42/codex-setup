# DeepSeek V4.1 Flash в Claude Code (OpenCode Go)

> Добавлено: 2026-09-11. Провайдер: **OpenCode Go** (`https://opencode.ai/zen/go`).
> Ярлык: `Desktop\Claude\DeepSeek V4.1 Flash (OpenCode Go).vbs`.

## Что это

Отдельный ярлык Claude Code на модели **DeepSeek V4.1 Flash** через провайдера OpenCode Go,
effort **low**. Запускается в изолированном профиле `C:\Users\user\.claude-go`.

**Важно:** глобальный `C:\Users\user\.claude\settings.json` (DashScope) **не изменён**.
Обычный `claude` и остальные 36 ярлыков продолжают работать на DashScope, как раньше.

## Как устроено (профиль A++)

| Компонент | Путь | Назначение |
|-----------|------|-----------|
| Профиль | `C:\Users\user\.claude-go\` | отдельный `CLAUDE_CONFIG_DIR` (копия настроек, но на Go) |
| Настройки | `.claude-go\settings.json` | endpoint `http://127.0.0.1:1889`, модели DeepSeek V4.1 Flash, effort low |
| Прокси | `.claude-go\opencode-go-proxy.cjs` | добавляет ключ OpenCode Go и заголовок `x-opencode-session` |
| Лаунчер | `.claude-go\launch-go.ps1` | поднимает прокси (порт 1889) и запускает `claude` |
| Ярлык | `Desktop\Claude\DeepSeek V4.1 Flash (OpenCode Go).vbs` | WezTerm + pwsh + лаунчер |

> Копии лаунчера и прокси для воспроизведения лежат в репозитории: `setup\opencode-go\`.

Почему прокси: OpenCode Go требует заголовок `x-opencode-session`; Claude Code его в этой
конфигурации не отправляет, из-за чего прямой запрос зависает. Прокси добавляет заголовок
и подставляет ключ из `~/.local/share/opencode/auth.json` (провайдер `opencode-go`).

Почему `--setting-sources user` в лаунчере: ярлык стартует в каталоге `C:\Users\user`, и
Claude Code читает `C:\Users\user\.claude\settings.json` как **project-настройки**, которые
перебивают профиль Go. Это давало ошибку DashScope (`InvalidParameter: model does not exist`)
и effort `medium`. Флаг `--setting-sources user` загружает только пользовательские настройки
из `C:\Users\user\.claude-go\settings.json` (Go) и игнорирует project-настройки каталога.

## Запуск

Двойной клик по ярлыку `DeepSeek V4.1 Flash (OpenCode Go).vbs`.
Прокси стартует автоматически при первом запуске и переиспользуется дальше.

## Диагностика

```powershell
# Прокси слушает порт 1889?
try { $c=New-Object System.Net.Sockets.TcpClient; $c.Connect('127.0.0.1',1889); 'OPEN'; $c.Close() } catch { 'CLOSED' }

# Лог прокси (по умолчанию: метод/путь/статус; тела — при OPENCODE_GO_DEBUG=1)
Get-Content "$env:USERPROFILE\.claude-go\opencode-go-proxy.log" -Tail 20

# Ручной запуск лаунчера (мимо ярлыка)
& "$env:USERPROFILE\.claude-go\launch-go.ps1"
```

Остановить прокси:

```powershell
Get-CimInstance Win32_Process -Filter "Name='node.exe'" |
  Where-Object { $_.CommandLine -like '*opencode-go-proxy*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

## Откат

Удалить профиль и ярлык — глобальный Claude не затронут:

```powershell
# Ярлык
Remove-Item "$env:USERPROFILE\Desktop\Claude\DeepSeek V4.1 Flash (OpenCode Go).vbs"
# Профиль (осторожно: содержит копию .credentials.json)
# Remove-Item "$env:USERPROFILE\.claude-go" -Recurse
```

## Ограничения

- OpenCode Go — платная подписка ($10/мес, лимиты по моделям); DeepSeek V4.1 Flash — $15/мес.
- Claude Code выдаёт предупреждение `unrecognized_model` (модель не в его каталоге) — безвредно.
- Прокси работает только пока запущен node-процесс (лаунчер поднимает его автоматически).

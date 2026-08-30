# Инструкция для агента: Автоматическая настройка Codex

Выполни все шаги по порядку. Не пропускай шаги.

## Шаг 1: Установка Codex

```powershell
# Установи Codex
powershell -ExecutionPolicy Bypass -c '$env:CODEX_NON_INTERACTIVE=1; irm https://chatgpt.com/codex/install.ps1 | iex'
```

**Проверь что установился:**
```powershell
# Проверь версию
& "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --version
```

## Шаг 2: Установка переменных окружения

```powershell
# DashScope ключ (безлимитный, 246 моделей)
[Environment]::SetEnvironmentVariable("DASHSCOPE_API_KEY", "YOUR_DASHSCOPE_API_KEY", "User")
$env:DASHSCOPE_API_KEY = "YOUR_DASHSCOPE_API_KEY"

# KKToken ключ (Claude модели)
[Environment]::SetEnvironmentVariable("KKTOKEN_API_KEY", "YOUR_KKTOKEN_API_KEY", "User")
$env:KKTOKEN_API_KEY = "YOUR_KKTOKEN_API_KEY"

# Tooken Club ключ (Claude/GPT модели)
[Environment]::SetEnvironmentVariable("TOOKEN_API_KEY", "YOUR_TOOKEN_API_KEY", "User")
$env:TOOKEN_API_KEY = "YOUR_TOOKEN_API_KEY"
```

**Проверь что переменные установлены:**
```powershell
Write-Host "DASHSCOPE_API_KEY: $env:DASHSCOPE_API_KEY"
Write-Host "KKTOKEN_API_KEY: $env:KKTOKEN_API_KEY"
Write-Host "TOOKEN_API_KEY: $env:TOOKEN_API_KEY"
```

## Шаг 3: Создание папок

```powershell
# Создай папку конфигов
if (-not (Test-Path "~\.codex")) {
    New-Item -ItemType Directory -Path "~\.codex" -Force
}

# Создай папку для батников
if (-not (Test-Path "~\Desktop\Codex")) {
    New-Item -ItemType Directory -Path "~\Desktop\Codex" -Force
}
```

## Шаг 4: Клонирование репозитория

```powershell
# Клонируй репозиторий
Set-Location ~\Desktop
git clone https://github.com/Misha-42/codex-setup.git
```

## Шаг 5: Копирование конфигов

```powershell
# Скопируй конфиги
Copy-Item "~\Desktop\codex-setup\config\config.toml" "~\.codex\" -Force
Copy-Item "~\Desktop\codex-setup\config\dashscope.config.toml" "~\.codex\" -Force

# Проверь что скопировались
Write-Host "config.toml: $(Test-Path '~\.codex\config.toml')"
Write-Host "dashscope.config.toml: $(Test-Path '~\.codex\dashscope.config.toml')"
```

## Шаг 6: Копирование батников

```powershell
# Скопируй все батники
Copy-Item "~\Desktop\codex-setup\bat-files\*" "~\Desktop\Codex\" -Force

# Проверь что скопировались
$batCount = (Get-ChildItem "~\Desktop\Codex" -Filter "*.bat").Count
Write-Host "Батников скопировано: $batCount"
```

## Шаг 7: Копирование скриптов

```powershell
# Скопируй скрипты
Copy-Item "~\Desktop\codex-setup\scripts\*" "~\" -Force

# Проверь что скопировались
Write-Host "codex-ds.ps1: $(Test-Path '~\codex-ds.ps1')"
Write-Host "codex-auto-update.ps1: $(Test-Path '~\codex-auto-update.ps1')"
```

## Шаг 8: Проверка работоспособности

```powershell
# Проверь что Codex работает
Write-Host "=== ПРОВЕРКА CODEX ==="

# Проверь версию
$version = & "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --version 2>&1
Write-Host "Версия Codex: $version"

# Проверь переменные окружения
Write-Host "DASHSCOPE_API_KEY: $($env:DASHSCOPE_API_KEY -ne $null)"
Write-Host "KKTOKEN_API_KEY: $($env:KKTOKEN_API_KEY -ne $null)"
Write-Host "TOOKEN_API_KEY: $($env:TOOKEN_API_KEY -ne $null)"

# Проверь конфиги
Write-Host "config.toml: $(Test-Path '~\.codex\config.toml')"
Write-Host "dashscope.config.toml: $(Test-Path '~\.codex\dashscope.config.toml')"

# Проверь батники
$batCount = (Get-ChildItem "~\Desktop\Codex" -Filter "*.bat").Count
Write-Host "Батников: $batCount"

# Проверь скрипты
Write-Host "codex-ds.ps1: $(Test-Path '~\codex-ds.ps1')"
Write-Host "codex-auto-update.ps1: $(Test-Path '~\codex-auto-update.ps1')"

Write-Host "=== ПРОВЕРКА ЗАВЕРШЕНА ==="
```

## Шаг 9: Тестовый запуск

```powershell
# Запусти Codex с тестовой моделью
Write-Host "=== ТЕСТОВЫЙ ЗАПУСК ==="

# Попробуй запустить Codex с qwen3.8-flash
$result = & "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe" --model dashscope/qwen3.8-flash --skip-git-repo-check exec "Reply with exactly: SETUP OK" 2>&1

if ($result -match "TEST OK" -or $result -match "setup ok") {
    Write-Host "ТЕСТ ПРОЙДЕН!" -ForegroundColor Green
} else {
    Write-Host "ТЕСТ НЕ ПРОЙДЕН: $result" -ForegroundColor Red
}

Write-Host "=== ТЕСТ ЗАВЕРШЕН ==="
```

## Шаг 10: Создание ярлыков на рабочем столе

```powershell
# Создай ярлыки на рабочем столе
$desktop = [Environment]::GetFolderPath("Desktop")

# Ярлык для основного Codex
$shortcutPath = "$desktop\Codex.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Users\user\AppData\Local\Programs\OpenAI\Codex\bin\codex.exe"
$shortcut.WorkingDirectory = "C:\Users\user"
$shortcut.Description = "OpenAI Codex"
$shortcut.Save()

Write-Host "Ярлык Codex создан: $shortcutPath"
```

## Готово!

### Что установлено:

| Компонент | Статус |
|-----------|--------|
| Codex | ✅ Установлен |
| DashScope ключ | ✅ Настроен |
| KKToken ключ | ✅ Настроен |
| Tooken Club ключ | ✅ Настроен |
| Конфиги | ✅ Скопированы |
| Батники | ✅ Скопированы |
| Скрипты | ✅ Скопированы |

### Доступные модели:

| Провайдер | Модели | Ключ |
|-----------|--------|------|
| DashScope | 246 моделей | sk-4deb... |
| KKToken | Claude Opus 5, Opus 4.8 | sk-HPb2... |
| Tooken Club | Claude, GPT-5.6 | tc_live_... |

### Батники на рабочем столе:

- `Qwen Flash.bat` - qwen3.6-flash
- `Qwen 3.8 Flash.bat` - qwen3.8-flash
- `qwen3.8-max.bat` - qwen3.8-max
- `Fast Coding.bat` - qwen3-coder-flash (2.5с)
- `Coding Max.bat` - qwen3.8-max
- `Code Review.bat` - qwen3.8-max
- `Claude Opus.bat` - claude-opus-5
- `GPT-5.6 Sol.bat` - gpt-5.6-sol
- И还有很多...

### Как пользоваться:

1. Запусти любой батник с рабочего стола
2. Нажми любую клавишу
3. Начни работать с Codex

### Автообновление моделей:

```powershell
# Обнови список моделей
~\codex-auto-update.ps1 -Force
```

### Мониторинг:

```powershell
# Проверь статус
~\codex-ds.ps1 -Status
```

## Решение проблем

### Codex не запускается
1. Проверь переменные окружения
2. Проверь конфиги в `~\.codex\`
3. Перезапусти терминал

### Модель не работает
1. Проверь список моделей: `~\codex-auto-update.ps1`
2. Попробуй другую модель
3. Проверь метаданные в config.toml

### Квота исчерпана
1. Проверь статус: `~\codex-ds.ps1 -Status`
2. Сбрось квоты: `~\codex-ds.ps1 -Reset`
3. Используй другую модель


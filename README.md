# Codex Setup - DashScope Unlimited

Быстрая настройка OpenAI Codex с безлимитным ключом DashScope (246 моделей).

## Быстрый старт

### 1. Установи Codex

```powershell
powershell -ExecutionPolicy Bypass -c '$env:CODEX_NON_INTERACTIVE=1; irm https://chatgpt.com/codex/install.ps1 | iex'
```

### 2. Установи переменные окружения

```powershell
# DashScope ключ (безлимитный)
setx DASHSCOPE_API_KEY "sk-4deb7c21bc32424290dfb2dc127f4054"

# KKToken ключ (Claude модели)
setx KKTOKEN_API_KEY "sk-HPb20qLtj5eNmgutGMn0Y9yqRlbGQ8SwqAsYDOOLYejd3uzu"

# Tooken Club ключ (Claude/GPT модели)
setx TOOKEN_API_KEY "tc_live_59a2a3bc4ed723b7b8c4b244f2c353bb288b5cef213d1d39"
```

### 3. Скопируй конфиги

```powershell
# Создай папку конфигов
mkdir ~\.codex

# Скопируй конфиги из репозитория
Copy-Item config\config.toml ~\.codex\
Copy-Item config\dashscope.config.toml ~\.codex\
```

### 4. Скопируй батники

```powershell
# Создай папку для батников
mkdir ~\Desktop\Codex

# Скопируй батники
Copy-Item bat-files\* ~\Desktop\Codex\
```

### 5. Скопируй скрипты

```powershell
# Скопируй скрипты
Copy-Item scripts\* ~\
```

## Доступные модели

### DashScope (246 моделей)

| Модель | Описание |
|--------|----------|
| `qwen3.8-max` | Новейшая, максимальная |
| `qwen3.8-flash` | Быстрая |
| `qwen3.7-max` | Стабильная |
| `qwen3.7-plus` | Баланс |
| `qwen3.6-flash` | Классическая |
| `deepseek-v4-pro` | DeepSeek Pro |
| `deepseek-v4-flash` | DeepSeek Flash |
| `ZHIPU/GLM-5.3` | GLM новейшая |
| `kimi-k3` | Kimi |

### KKToken (Claude модели)

| Модель | Описание |
|--------|----------|
| `claude-opus-5` | Claude Opus 5 |
| `claude-opus-4-8` | Claude Opus 4.8 |

### Tooken Club (Claude/GPT модели)

| Модель | Описание |
|--------|----------|
| `claude-opus-5` | Claude Opus 5 |
| `claude-sonnet-5` | Claude Sonnet 5 |
| `gpt-5.6-sol` | GPT-5.6 Sol |
| `gpt-5.6-luna` | GPT-5.6 Luna |
| `gpt-5.6-terra` | GPT-5.6 Terra |

## Батники

### Flash модели (быстрые)
- `Qwen Flash.bat` - qwen3.6-flash
- `Qwen 3.8 Flash.bat` - qwen3.8-flash
- `DeepSeek Flash.bat` - deepseek-v4-flash
- `Fast Coding.bat` - qwen3-coder-flash (2.5с)

### Max модели (максимальное качество)
- `qwen3.8-max.bat` - qwen3.8-max
- `qwen3.7-max.bat` - qwen3.7-max
- `deepseek-v4-pro.bat` - deepseek-v4-pro
- `ZHIPU GLM-5.3.bat` - GLM-5.3

### Кодинг
- `Fast Coding.bat` - Быстрый код
- `Coding Max.bat` - Сложный код
- `DeepSeek Coding.bat` - Баланс
- `Code Review.bat` - Ревью кода

### Claude
- `Claude Opus.bat` - claude-opus-5 (KKToken)
- `Claude Opus 4.8.bat` - claude-opus-4-8 (KKToken)
- `Claude Sonnet.bat` - claude-sonnet-5 (Tooken)

### GPT
- `GPT-5.6 Sol.bat` - gpt-5.6-sol (Tooken)
- `GPT-5.6 Luna.bat` - gpt-5.6-luna (Tooken)
- `GPT-5.6 Terra.bat` - gpt-5.6-terra (Tooken)

## Скрипты

### codex-ds.ps1
Основной скрипт с ротацией моделей:
```powershell
.\codex-ds.ps1                    # Интерактивный режим
.\codex-ds.ps1 "задача"           # Одноразовая задача
.\codex-ds.ps1 -Status            # Статус квот
.\codex-ds.ps1 -Reset             # Сброс квот
```

### codex-auto-update.ps1
Автообновление моделей:
```powershell
.\codex-auto-update.ps1           # Обновить модели
.\codex-auto-update.ps1 -Force    # Принудительное обновление
```

### dashboard.ps1
Дашборд квот:
```powershell
.\dashboard.ps1                   # Запуск дашборда
```

## Конфигурация

### config.toml
Основной конфиг Codex:
- `model_provider = "dashscope"` - провайдер по умолчанию
- `model = "qwen3.6-flash"` - модель по умолчанию
- `model_context_window = 100000` - размер контекста

### Провайдеры

| Провайдер | URL | Ключ |
|-----------|-----|------|
| DashScope | dashscope.aliyuncs.com | DASHSCOPE_API_KEY |
| KKToken | kktoken.cc/v1 | KKTOKEN_API_KEY |
| Tooken Club | tooken.club/v1 | TOOKEN_API_KEY |

## Обновление

### Codex
```powershell
powershell -ExecutionPolicy Bypass -c '$env:CODEX_NON_INTERACTIVE=1; irm https://chatgpt.com/codex/install.ps1 | iex'
```

### Модели
```powershell
.\codex-auto-update.ps1 -Force
```

## Решение проблем

### Codex не запускается
1. Проверь переменные окружения: `$env:DASHSCOPE_API_KEY`
2. Проверь конфиг: `~\.codex\config.toml`
3. Запусти диагностику: `.\codex-ds.ps1 -Doctor`

### Модель не работает
1. Проверь список моделей: `.\codex-auto-update.ps1`
2. Проверь метаданные в config.toml
3. Попробуй другую модель

### Квота исчерпана
1. Проверь статус: `.\codex-ds.ps1 -Status`
2. Сбрось квоты: `.\codex-ds.ps1 -Reset`
3. Используй другую модель

## Лицензия

MIT


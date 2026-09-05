[![Версия](https://img.shields.io/badge/version-2.4.0-blue.svg)](https://github.com/xxphantom/remnawave-installer)
[![Язык](https://img.shields.io/badge/language-Bash-green.svg)]()
[![ОС](https://img.shields.io/badge/OS-Ubuntu-orange.svg)]()

[Read in English](README.md)

Автоматический установщик [Remnawave Panel](https://docs.rw/) — системы управления VPN/прокси с Docker и Caddy.

> [!CAUTION]
> Этот скрипт предоставляется как **образовательный пример**. Он не предназначен для использования в продакшене без полного понимания конфигураций Remnawave. **ИСПОЛЬЗУЙТЕ НА СВОЙ СТРАХ И РИСК!**

## Быстрый старт

```bash
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/xxphantom/remnawave-installer/main/install.sh)" @ --lang=ru
```

## Возможности

- **Режимы установки**: Только панель, Только нода, Всё-в-одном
- **Защита доступа**: Cookie security или полная аутентификация Caddy (2FA)
- **Автонастройка**: Docker, Caddy, UFW, PostgreSQL, Redis
- **Управление**: Обновления, перезапуск, удаление, бэкап учётных данных
- **Инструменты**: WARP интеграция, BBR, Rescue CLI, просмотр логов
- **Экстренный доступ**: Прямой доступ к панели на порту 8443 (Всё-в-одном)

## Требования

- **ОС**: Ubuntu 22.04+ или Debian
- **Доступ**: Root-права
- **Домены**: 3 уникальных домена с DNS A-записями, указывающими на ваш сервер
- **Порты**: 80, 443, SSH должны быть свободны

## Режимы установки

| Режим | Назначение |
|-------|------------|
| **Panel Only** | Панель управления на отдельном сервере |
| **Node Only** | Прокси-нода на отдельном сервере |
| **All-in-One** | Панель + Нода на одном сервере |

## Параметры командной строки

```bash
--lang=en|ru              # Язык интерфейса
--panel-branch=VERSION    # Версия панели: main, dev, alpha или X.Y.Z
--installer-branch=BRANCH # Ветка установщика: main или dev
--keep-caddy-data         # Сохранить сертификаты при переустановке
```

В режиме `main` устанавливаются [backend 3.4.3](https://github.com/remnawave/backend/releases/tag/3.4.3), [node 3.4.1](https://github.com/remnawave/node/releases/tag/3.4.1) и [subscription-page 8.0.0](https://github.com/remnawave/subscription-page/tree/8.0.0). Шаблон `.env` берётся из того же релиза, что и образ панели.

Меню обновления использует версии, указанные в установщике. Более новые версии с числовыми тегами сохраняются. Поэтому перед обновлением компонентов скачайте актуальный установщик.

Если оставить панель на 2.x, теги `latest` у ноды и страницы подписки заменятся на 2.8.0 и 7.2.6. При переходе на 3.x обновятся панель, нода и страница подписки на этом сервере. Перед обновлением отдельной ноды скрипт попросит подтвердить, что удалённая панель уже работает на 3.x.

В новых конфигурациях REALITY задано `minClientVer: "0.0.0"`, чтобы могли подключаться mihomo, sing-box и старые клиенты Xray. При обновлении панели скрипт предложит добавить этот параметр в профили, где минимальная версия не указана. Если версия уже задана, она сохранится. [Xray предупреждает](https://github.com/XTLS/Xray-core/blob/v26.7.28/infra/conf/transport_security.go), что снятие ограничения повышает риск блокировки IP со стороны GFW.

**Примеры:**
```bash
# Использовать конкретную версию панели
sudo bash -c "$(curl -sL ...)" @ --lang=ru --panel-branch=3.4.3

# Dev версия
sudo bash -c "$(curl -sL ...)" @ --lang=ru --panel-branch=dev
```

## После установки

**Учётные данные:** `/opt/remnawave/credentials.txt`

**Управление сервисами:**
```bash
cd /opt/remnawave
make start    # Запуск и просмотр логов
make stop     # Остановка сервисов
make restart  # Перезапуск сервисов
make logs     # Просмотр логов
```

## Документация

- [Архитектура и сценарии установки](docs/ARCHITECTURE.ru.md)
- [Решение проблем](docs/TROUBLESHOOTING.ru.md)

## Ссылки

- [Документация Remnawave](https://docs.rw/)
- [Telegram-канал](https://t.me/remnawave)
- [Telegram-группа](https://t.me/+xQs17zMzwCY1NzYy)
- [Обновления](https://t.me/remnalog)

---

Вопросы по скрипту: [@xxphantom](https://t.me/uphantom)

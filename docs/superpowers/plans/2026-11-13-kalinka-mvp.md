# Kalinka MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать и развернуть самостоятельный open-source продукт «Калинка» (Kalinka) на основе форка `calcom/cal.diy` с собственной сборкой Docker-образа, малиновым брендингом и рабочим HTTPS-доменом `ka-linka.ru`.

**Architecture:** Монорепозиторий на базе Turborepo 2.7 и Yarn Berry 4.12 с Next.js 16 веб-приложением (`apps/web`), Prisma ORM 6.16 и tRPC. Приложение пакуется в multi-stage Docker-образ, запускается в Docker Compose рядом с изолированным PostgreSQL, обслуживается Caddy reverse proxy с автоматическим SSL Let's Encrypt для домена `ka-linka.ru`.

**Tech Stack:** Next.js 16, React 19, TypeScript, Tailwind CSS v4, Prisma 6.16, PostgreSQL 16, Redis, Caddy 2, Docker & Docker Compose.

**Spec:** [docs/specs/kalinka-mvp.md](file:///home/polunin-michael/my/kalinka/docs/specs/kalinka-mvp.md)

## Global Constraints

- Сохранять полную историю коммитов и связь с upstream `https://github.com/calcom/cal.diy.git`.
- Не удалять и не изменять текст MIT-лицензии и копирайты Cal.com, Inc.
- Не производить массовых автозамен `cal`/`calendso` во внутренних схемах БД, Prisma, tRPC и именах пакетов во избежание регрессий.
- Никаких дефолтных паролей (`unicorn_user`, `secret`) в production окружении.
- База данных PostgreSQL и Redis не должны иметь публичных портов наружу.
- Не коммитить `.env` файлы с реальными паролями и ключами.
- Не производить покупку домена/сервера или смену рабочих DNS без подтверждения пользователя.

## Review Focus

1. **Next.js static URL placeholder leak**: `replace-placeholder.sh` должен корректно заменять `http://NEXT_PUBLIC_WEBAPP_URL_PLACEHOLDER` на `https://ka-linka.ru` в production бандле.
2. **First-admin registration gate**: `/auth/setup` должен быть доступен только при `userCount === 0`, после создания первого пользователя роут должен блокироваться (`400 No setup needed`).
3. **Internal network exposure**: В `docker-compose.yml` порты 5432, 6379 и 5555 не должны быть открыты на `0.0.0.0`.
4. **Build OOM risk**: `Dockerfile` и параметры VPS должны резервировать не менее 6GB виртуальной памяти (`NODE_OPTIONS=--max-old-space-size=6144` + swap 4GB).
5. **No external dependencies block**: Проверить, что создание встречи с локацией "In Person" / "Custom Link" не требует ключей Daily.co, Zoom или Google API.

---

### Task 1: Подготовка конфигурации окружения и валидация базовой схемы

**Files:**
- Create: `docker-compose.production.yml`
- Create: `.env.production.example`
- Create: `Caddyfile`
- Modify: `docker-compose.yml:37-67`

**Interfaces:**
- Consumes: `Dockerfile`, `.env.example`, `packages/prisma/schema.prisma`
- Produces: Валидированные compose-манифесты и шаблоны переменных окружения для Kalinka.

- [ ] **Step 1: Создать безопасный шаблон переменных `.env.production.example`**
  Определить параметры `NEXTAUTH_SECRET`, `CALENDSO_ENCRYPTION_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `DATABASE_HOST=database`, `NEXT_PUBLIC_WEBAPP_URL=https://ka-linka.ru`, `NEXT_PUBLIC_APP_NAME=Kalinka`, `CALCOM_TELEMETRY_DISABLED=1`.

- [ ] **Step 2: Создать конфигурацию Caddy (`Caddyfile`)**
  Настроить автоматический HTTPS для `ka-linka.ru`, проксирование на `kalinka:3000`, безопасные заголовки (X-Content-Type-Options, HSTS).

- [ ] **Step 3: Настроить `docker-compose.production.yml` для production-развертывания**
  - Сервис `kalinka` (билд из локального контекста `Dockerfile`, образ `kalinka:latest`).
  - Сервис `database` (PostgreSQL, том `database-data`, без экспорта порта на хост).
  - Сервис `redis` (Redis, без экспорта порта на хост).
  - Сервис `caddy` (Caddy, порты 80:80 и 443:443, примонтированный `Caddyfile`).
  - Полностью исключить сервисы `studio` и публичный порт 80 сервиса `calcom-api`.

- [ ] **Step 4: Проверить валидность docker compose конфигурации**
  Run: `docker compose -f docker-compose.production.yml config`
  Expected: Успешная валидация без синтаксических ошибок.

- [ ] **Step 5: Коммит изменений конфигурации**
  ```bash
  git add docker-compose.production.yml .env.production.example Caddyfile
  git commit -m "chore(infra): add production docker-compose and caddy configuration for kalinka"
  ```

---

### Task 2: Создание визуальных ресурсов маскота «Малина» и брендинга

**Files:**
- Create: `apps/web/public/cal-com-icon.svg` (замена маскотом малины)
- Create: `apps/web/public/cal-com-icon-white.svg` (малина в белом монохроме)
- Create: `apps/web/public/cal-logo-word.svg` (логотип Kalinka)
- Create: `apps/web/public/cal-logo-word-black.svg`
- Create: `apps/web/public/calcom-logo-white-word.svg`
- Modify: `apps/web/public/site.webmanifest`
- Modify: `apps/web/app/api/logo/route.ts`

**Interfaces:**
- Consumes: Требования спецификации к малиновой айдентике.
- Produces: Комплект SVG/PNG ассетов и манифеста для веб-интерфейса и PWA.

- [ ] **Step 1: Разработать векторный маскот-иконку «Малина» (SVG)**
  Создать чистый, современный геометрический SVG маскота малины с ягодной структурой и зеленым листиком (основной цвет `#E11D48`).
  Записать в `apps/web/public/cal-com-icon.svg` и светлую версию `apps/web/public/cal-com-icon-white.svg`.

- [ ] **Step 2: Разработать логотипы Kalinka (SVG)**
  Создать текстовый логотип «Kalinka» с фирменным знаком маскота для светлой и темной тем оформления.
  Записать в `apps/web/public/cal-logo-word.svg`, `apps/web/public/cal-logo-word-black.svg` и `apps/web/public/calcom-logo-white-word.svg`.

- [ ] **Step 3: Обновить манифест приложения `apps/web/public/site.webmanifest`**
  Заменить `"name": "Cal.diy"` на `"name": "Kalinka"`, `"short_name": "Kalinka"`, тему на `#E11D48`.

- [ ] **Step 4: Проверить валидность SVG файлов и структуры манифеста**
  Run: `python3 -c "import xml.etree.ElementTree as ET, json; ET.parse('apps/web/public/cal-com-icon.svg'); json.load(open('apps/web/public/site.webmanifest')); print('OK')"`
  Expected: `OK`

- [ ] **Step 5: Коммит визуальных ресурсов**
  ```bash
  git add apps/web/public/cal* apps/web/public/site.webmanifest
  git commit -m "feat(branding): add kalinka raspberry mascot and visual identity assets"
  ```

---

### Task 3: Обновление цветовой темы и базовых констант брендинга

**Files:**
- Modify: `packages/config/theme/tokens.css:331-335, 455-459`
- Modify: `packages/lib/constants.ts:38-43`
- Modify: `packages/ui/components/logo/Logo.tsx:20-27`
- Modify: `packages/i18n/locales/ru/common.json`
- Modify: `packages/i18n/locales/en/common.json`

**Interfaces:**
- Consumes: Малиновые цвета спецификации (`#E11D48` / `#BE123C`).
- Produces: Обновленные CSS-переменные бренда и строковые константы.

- [ ] **Step 1: Обновить CSS-переменные бренда в `packages/config/theme/tokens.css`**
  Установить малиновые оттенки:
  - В Light mode:
    `--cal-brand: hsla(346, 77%, 49%, 1);` (`#E11D48`)
    `--cal-brand-emphasis: hsla(343, 79%, 41%, 1);` (`#BE123C`)
    `--cal-brand-text: hsla(0, 0%, 100%, 1);`
  - В Dark mode:
    `--cal-brand: hsla(349, 95%, 71%, 1);` (`#FB7185`)
    `--cal-brand-emphasis: hsla(350, 89%, 60%, 1);` (`#F43F5E`)
    `--cal-brand-text: hsla(0, 0%, 0%, 1);`

- [ ] **Step 2: Обновить дефолтные значения в `packages/lib/constants.ts`**
  - `APP_NAME = process.env.NEXT_PUBLIC_APP_NAME || "Kalinka";`
  - `COMPANY_NAME = process.env.NEXT_PUBLIC_COMPANY_NAME || "Kalinka Team";`
  - `SENDER_NAME = process.env.NEXT_PUBLIC_SENDGRID_SENDER_NAME || "Kalinka";`
  - `SUPPORT_MAIL_ADDRESS = process.env.NEXT_PUBLIC_SUPPORT_MAIL_ADDRESS || "support@ka-linka.ru";`
  - `WEBSITE_URL = ensureProtocol(process.env.NEXT_PUBLIC_WEBSITE_URL) || "https://ka-linka.ru";`

- [ ] **Step 3: Обновить атрибуты `alt` и `title` в `packages/ui/components/logo/Logo.tsx`**
  Заменить `alt="Cal.diy"` и `title="Cal.diy"` на `"Kalinka"`.

- [ ] **Step 4: Обновить ключевые строки в локализации `locales/ru/common.json` и `locales/en/common.json`**
  Заменить упоминания `Cal.diy` на `Kalinka` / `Калинка` в заголовках регистрации, логина и приветствия (`welcome_to_cal_com`, `sign_in_to_cal_com`, `create_your_calcom_account`).

- [ ] **Step 5: Проверить валидность JSON файлов локализации**
  Run: `python3 -c "import json; json.load(open('packages/i18n/locales/ru/common.json')); json.load(open('packages/i18n/locales/en/common.json')); print('JSON VALID')"`
  Expected: `JSON VALID`

- [ ] **Step 6: Коммит стилей и констант**
  ```bash
  git add packages/config/theme/tokens.css packages/lib/constants.ts packages/ui/components/logo/Logo.tsx packages/i18n/locales/
  git commit -m "feat(branding): apply raspberry theme palette and kalinka brand constants"
  ```

---

### Task 4: Локальная сборка и проверка собственного Docker-образа

**Files:**
- Modify: `Dockerfile` (если требуются оптимизации сборки)
- Modify: `scripts/start.sh`

**Interfaces:**
- Consumes: Измененные исходники форка Kalinka.
- Produces: Локальный Docker-образ `kalinka:latest` и успешный запуск тестового стека.

- [ ] **Step 1: Выполнить тестовую сборку Docker-образа `kalinka:latest`**
  Run: `docker build -t kalinka:latest .`
  Expected: Успешное завершение многоэтапного билда (`runner` stage готов, exit code 0).

- [ ] **Step 2: Запустить тестовый стек через Docker Compose**
  Запустить стек с локальным тестовым `.env`:
  Run: `docker compose -f docker-compose.production.yml up -d database redis kalinka`
  Expected: Все контейнеры переходят в состояние `Up` (healthy).

- [ ] **Step 3: Проверить лог запуска и миграции Prisma**
  Run: `docker compose -f docker-compose.production.yml logs kalinka | grep "database is up"`
  Expected: Наличие сообщения о готовности базы и успешном выполнении миграций.

- [ ] **Step 4: Проверить HTTP-ответ локального инстанса**
  Run: `curl -I http://localhost:3000/auth/login`
  Expected: HTTP 200 OK или HTTP 307 Redirect с заголовками Next.js.

- [ ] **Step 5: Остановить тестовый стек**
  Run: `docker compose -f docker-compose.production.yml down`
  Expected: Контейнеры корректно остановлены.

---

### Task 5: Документация проекта и подготовка к релизу

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: Готовая конфигурация и протестированный билд.
- Produces: Документированный открытый репозиторий с инструкциями по установке.

- [ ] **Step 1: Обновить `README.md`**
  - Добавить заголовок проекта: **«Калинка» (Kalinka) — Open Source Scheduling Platform**.
  - Описать цели продукта, лицензию (MIT) и благодарность авторам Cal.com / Cal.diy.
  - Привести пошаговое руководство по быстрому запуску в Docker Compose.
  - Описать структуру переменных окружения.

- [ ] **Step 2: Коммит и push в форк**
  ```bash
  git add README.md
  git commit -m "docs: update README with Kalinka project documentation and deployment instructions"
  # Публиковать после согласования с владельцем.
  ```
  Expected: Успешный push в `git@github.com:p1nkma/kalinka.git`.

---

### Task 6: Деплой на целевой сервер и привязка домена `ka-linka.ru`

*(Выполняется после согласования с пользователем доступа к VPS и привязки A-записи в Timeweb)*

**Files:**
- Server: `/opt/kalinka`
- Server: `/opt/kalinka/.env`

**Interfaces:**
- Consumes: Linux VPS с настроенной A-записью `ka-linka.ru`.
- Produces: Работающий HTTPS сервис на `https://ka-linka.ru`.

- [ ] **Step 1: Подготовить VPS окружение**
  Проверить наличие Docker, Docker Compose, настроить swap (4GB при необходимости).

- [ ] **Step 2: Развернуть форк репозитория на сервере**
  Склонировать репозиторий `p1nkma/kalinka` в `/opt/kalinka`.

- [ ] **Step 3: Создать production `.env` на сервере**
  Использовать команды из `.env.production.example`. Для `NEXTAUTH_SECRET` - `openssl rand -base64 32`, для `CALENDSO_ENCRYPTION_KEY` - `openssl rand -base64 24`, для пароля PostgreSQL - `openssl rand -hex 24`.

- [ ] **Step 4: Собрать собственный образ и запустить стек**
  Run: `docker compose --env-file .env.production -f docker-compose.production.yml up -d --wait` после сборки и первичного setup по инструкции в [руководстве](../../kalinka-deployment.md).
  Expected: Контейнеры `kalinka`, `database`, `caddy` успешно запущены.

- [ ] **Step 5: Проверить выпуск SSL сертификата Caddy**
  Run: `docker compose -f docker-compose.production.yml logs caddy | grep -i "certificate obtained"`
  Expected: Сертификат Let's Encrypt для `ka-linka.ru` получен.

- [ ] **Step 6: Проверить доступность по HTTPS**
  Run: `curl -sIv https://ka-linka.ru | grep -E "HTTP/|SSL certificate"`
  Expected: HTTP 200/307, валидный SSL.

---

### Task 7: End-to-End функциональная приемка (Smoke Tests)

**Interfaces:**
- Consumes: Работающий инстанс `https://ka-linka.ru`.
- Produces: Доказательство полной функциональной работоспособности.

- [ ] **Step 1: Пройти первичную настройку `/auth/setup`**
  Открыть `https://ka-linka.ru/auth/setup`, создать первого администратора (email, имя, надежный пароль).

- [ ] **Step 2: Создать тип встречи (Event Type)**
  В панели управления создать событие «Консультация 30 мин» (длительность 30 мин, локация «Личная встреча / In person» или «Ссылка на звонок»).

- [ ] **Step 3: Проверить и настроить расписание доступности**
  Убедиться, что настроены рабочие часы (например, Пн-Пт 09:00 - 18:00) и таймзона (Europe/Moscow).

- [ ] **Step 4: Открыть публичную страницу бронирования инкогнито**
  Открыть `https://ka-linka.ru/{username}/{event-slug}` в приватной сессии без авторизации.
  Убедиться, что отображается бренд Kalinka, маскот-малина и календарная сетка свободных слотов.

- [ ] **Step 5: Забронировать свободный слот**
  Выбрать дату и время, указать имя гостя («Тестовый Клиент») и email. Подтвердить бронирование.
  Expected: Переход на страницу `booking-successful` с деталями брони.

- [ ] **Step 6: Проверить появление бронирования у организатора**
  В кабинете организатора открыть вкладку «Бронирования» (Bookings).
  Expected: Забронированная встреча присутствует в списке со статусом «Предстоящие».

- [ ] **Step 7: Проверить сохранение данных после рестарта**
  Run: `docker compose -f docker-compose.production.yml restart`
  После рестарта обновить страницу бронирований.
  Expected: Все встречи и настройки сохранены, PostgreSQL данные не утеряны.

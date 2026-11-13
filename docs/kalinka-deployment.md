# Запуск Kalinka

## Локальная проверка

Из корня репозитория соберите образ. Для сборки нужны Docker, доступ к реестрам образов и пакетов, а также к Google Fonts для загрузки Inter. Сборку можно выполнить на отдельной машине той же архитектуры, что и сервер.

```sh
docker build -t kalinka:latest .
```

Один раз создайте файл для локальных секретов. При повторном запуске используйте прежний файл, чтобы сохранить доступ к базе и зашифрованным данным.

```sh
(
  set -C
  umask 077
  {
    printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)"
    printf 'NEXTAUTH_SECRET=%s\n' "$(openssl rand -base64 32)"
    printf 'CALENDSO_ENCRYPTION_KEY=%s\n' "$(openssl rand -base64 24)"
  } > .env.kalinka-local
)
docker compose --env-file .env.kalinka-local -f docker-compose.local.yml up -d --wait
```

Откройте `http://localhost:3000/auth/setup`. Создайте администратора и войдите с его учётными данными. Для проверки встречи без внешних интеграций используйте место проведения «Личная встреча» или собственную ссылку.

## Первый запуск на VPS

1. На сервере проверьте `docker info`, `docker compose version`, `df -h`, `free -h` и `ss -ltn`. Сверьте архитектуру сервера с образом. Caddy использует порты TCP 80 и 443. PostgreSQL и Next.js доступны только по внутренней сети Docker. Бронирование работает без Redis. Интеграция Cal.diy с Redis использует Upstash REST и требует отдельной настройки.
2. Возьмите проверенный коммит форка. Соберите образ с тегом коммита или перенесите его через `docker save` и `docker load`. Для экземпляра с одним владельцем установите `NEXT_PUBLIC_DISABLE_SIGNUP=true` при сборке. Администратор по-прежнему создаётся через setup.
3. Скопируйте `.env.production.example` в `.env.production` с правами 0600. Укажите домен, действующий ACME email и тег образа. Сгенерируйте пароль БД в hex и два разных ключа командами из шаблона. Ключ AES должен содержать ровно 32 ASCII-символа. Заполните SMTP для доставки уведомлений и писем восстановления пароля. Домен Caddy и публичный URL приложения определяются из `DOMAIN`.

```sh
tag=$(git rev-parse --short=12 HEAD)
docker build --build-arg NEXT_PUBLIC_DISABLE_SIGNUP=true \
  --label "org.opencontainers.image.revision=$(git rev-parse HEAD)" \
  -t "kalinka:$tag" .
dc() { docker compose --env-file .env.production -f docker-compose.production.yml "$@"; }
dc config --quiet
```

4. Создайте первого администратора до открытия публичного доступа. Временный Compose override ниже публикует приложение только на loopback сервера. Caddy на этом этапе не запускается.

```sh
cat > compose.bootstrap.yml <<'YAML'
services:
  kalinka:
    ports: ["127.0.0.1:3000:3000"]
    environment:
      NEXT_PUBLIC_WEBAPP_URL: http://localhost:3000
      NEXTAUTH_URL: http://localhost:3000/api/auth
YAML
docker compose --env-file .env.production -f docker-compose.production.yml \
  -f compose.bootstrap.yml up -d --wait kalinka
```

   На своём компьютере откройте SSH-туннель командой `ssh -N -L 3000:127.0.0.1:3000 user@server`. Через него откройте `http://localhost:3000/auth/setup`, создайте администратора, завершите первоначальную настройку профиля и включите 2FA в настройках безопасности. Войдите заново с одноразовым кодом, чтобы активировать роль администратора. Для туннеля локальный порт 3000 должен быть свободен.

5. После согласования публикации направьте A-запись домена на VPS. Публикуйте AAAA только если VPS принимает соединения по IPv6. Проверьте DNS, откройте 80/443 и запустите основной Compose. Конфигурация без override пересоздаст веб-контейнер с HTTPS URL и без привязки к порту 3000. Caddy получит сертификат для указанного домена. Для другого домена измените `DOMAIN` и пересоздайте сервисы `kalinka` и `caddy`.

```sh
dc up -d --wait
dc ps
dc logs --tail=100 kalinka caddy
curl -fI "http://ka-linka.ru"
curl -fsS "https://ka-linka.ru/api/version"
```

Проверьте вход, создание встречи и публичное бронирование. При настроенном SMTP отдельно проверьте получение уведомления. Для дополнительного домена потребуется его DNS и конфигурация Caddy.

## Резервное копирование и обновление

Сохраните дамп PostgreSQL и отдельно сохраните `.env.production` в защищённом хранилище. Ключ шифрования нужен для восстановления подключённых интеграций. Храните копию вне VPS. Регулярно проверяйте восстановление в отдельной базе. Тома Caddy содержат сертификаты и ключи. При переносе сервера переносите их защищённым способом или дайте Caddy получить сертификаты заново.

```sh
umask 077
backup="kalinka-$(date -u +%Y%m%dT%H%M%SZ).dump"
dc exec -T database sh -ec 'pg_dump -Fc -U "$POSTGRES_USER" -d "$POSTGRES_DB"' > "$backup"
test -s "$backup" && dc exec -T database pg_restore --list < "$backup"
```

Для обновления сделайте резервную копию, сохраните тег текущего образа, соберите новый образ с тегом проверенного коммита и измените `KALINKA_TAG`. Выполните `dc up -d --wait kalinka`, проверьте журнал миграций и повторите проверку бронирования. Если новая версия изменила схему несовместимо, для отката потребуется восстановить дамп до обновления. Перед восстановлением остановите веб-сервис и сохраните текущее состояние базы.

При смене домена приложение применяет публичный URL при старте контейнера. Параметры `NEXT_PUBLIC_DISABLE_SIGNUP`, `NEXT_PUBLIC_SUPPORT_MAIL_ADDRESS`, `NEXT_PUBLIC_WEBSITE_TERMS_URL` и `NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL` задаются при сборке. Укажите актуальные контакты и документы владельца для публичного сервиса.

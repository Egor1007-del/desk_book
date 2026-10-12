# Desk Book

Справочник сотрудников организации на Ruby on Rails.

## Начальные данные

Примените миграции и загрузите начальные данные:

```bash
bin/rails db:migrate
bin/rails db:seed
```

Seeds создают три должности, роли `admin` и `employee`, а также первоначального администратора. Его логин и пароль можно передать через переменные окружения:

```bash
ADMIN_LOGIN=admin ADMIN_PASSWORD=change-me bin/rails db:seed
```

Переменные также можно экспортировать для текущей оболочки:

```bash
export ADMIN_LOGIN=admin
export ADMIN_PASSWORD=change-me
bin/rails db:seed
```

Если переменные не заданы, используются учебные значения `admin`/`admin`. Не используйте стандартный пароль при реальном развёртывании. Повторный запуск seeds не перезаписывает пароль существующего администратора.

Проект не загружает `.env` автоматически. Не добавляйте `.env` с рабочими учётными данными и другими секретами в Git.

## Базы данных

В development и test приложение использует SQLite. В production используется PostgreSQL, адрес которой Rails получает из переменной окружения `DATABASE_URL`.

Такое разделение оставляет простой локальный запуск через `bin/dev`, но не привязывает production-данные к временной файловой системе контейнера. На Render PostgreSQL работает как отдельный управляемый сервис и сохраняет данные независимо от деплоев Rails-приложения.

## Docker

Docker-образ — неизменяемый шаблон с Ruby, системными библиотеками, гемами, собранными ассетами и кодом приложения. Контейнер — запущенный процесс, созданный из этого образа.

Проверьте доступность Docker Engine и Compose:

```bash
docker --version
docker compose version
```

Если Docker установлен, но команда отвечает `permission denied` для `/var/run/docker.sock`, текущая пользовательская сессия ещё не получила членство в группе `docker`. Выйдите из Ubuntu и войдите снова либо временно откройте новую shell-сессию командой `newgrp docker`, затем повторите проверку.

Для локального production-подобного запуска передайте Rails master key и стойкий пароль первоначального администратора:

```bash
RAILS_MASTER_KEY="$(cat config/master.key)" \
ADMIN_LOGIN=admin \
ADMIN_PASSWORD=change-me-now \
docker compose up --build
```

Compose соберёт Rails-образ, запустит контейнеры `web` и `db`, дождётся готовности PostgreSQL и откроет приложение на `http://localhost:3000`. При запуске Rails выполнит миграции и идемпотентный `db:seed`.

Полезные команды:

```bash
docker compose ps
docker compose logs -f web
docker compose exec web bin/rails console
docker compose down
```

`docker compose down` удаляет контейнеры и сеть, но сохраняет именованный volume `postgres_data`. Поэтому PostgreSQL-данные появятся снова при следующем запуске. Команда ниже дополнительно удаляет volume и локальную базу; не выполняйте её, если данные нужны:

```bash
docker compose down --volumes
```

### Как устроен Dockerfile

- `FROM` выбирает базовый Ruby-образ и начинает build- или runtime-стадию.
- `WORKDIR /rails` задаёт рабочий каталог последующих команд и запущенного приложения.
- `COPY` переносит lock-файлы и исходный код в образ. Сначала копируются файлы зависимостей, чтобы Docker мог повторно использовать кеш слоёв.
- `RUN` устанавливает системные пакеты, гемы и JavaScript-зависимости, затем компилирует Bootsnap, CSS и Rails-ассеты.
- `ENV` задаёт production-режим Bundler и Rails внутри образа. Секреты через него не записываются.
- `ENTRYPOINT` всегда запускает `bin/docker-entrypoint`, который подготавливает и заполняет базу перед стартом сервера.
- `HEALTHCHECK` периодически запрашивает `/up` внутри контейнера и отмечает его нездоровым, если Rails не отвечает.
- `CMD` задаёт команду по умолчанию: Thruster запускает Puma и обслуживает HTTP-запросы.

Dockerfile многоэтапный. Node.js, Yarn, компиляторы и заголовочные файлы PostgreSQL используются на стадии `build`, но не копируются в финальный runtime-образ. Это уменьшает размер образа и поверхность атаки.

## Render

Render собирает приложение непосредственно из `Dockerfile`. Загружать образ в Docker Hub не требуется. Файл `render.yaml` описывает два ресурса:

- Docker Web Service `desk-book`;
- управляемую PostgreSQL `desk-book-db`.

`DATABASE_URL` передаётся Web Service автоматически из созданной базы. Значения `RAILS_MASTER_KEY`, `ADMIN_LOGIN` и `ADMIN_PASSWORD` не хранятся в репозитории: Render запросит их при создании Blueprint.

Первый деплой:

1. Отправьте проект в репозиторий GitHub, GitLab или Bitbucket.
2. В Render откройте **New → Blueprint** и подключите репозиторий.
3. Подтвердите ресурсы из `render.yaml`.
4. Введите `RAILS_MASTER_KEY` из локального `config/master.key`.
5. Задайте `ADMIN_LOGIN` и стойкий `ADMIN_PASSWORD`.
6. Запустите создание Blueprint и дождитесь успешного health check `/up`.
7. Откройте выданный Render адрес `https://...onrender.com` и войдите заданными учётными данными.

Render задаёт контейнеру переменную `PORT`. Entrypoint передаёт её Thruster как `HTTP_PORT`, поэтому публичный HTTP-сервер слушает требуемый платформой адрес и порт. Внутренний Puma продолжает работать на своём целевом порту.

Docker Compose на Render не запускается. Он нужен только локально. `render.yaml` выполняет похожую организационную задачу на платформе Render: создаёт Web Service и PostgreSQL и связывает их через переменные окружения.

Тарифы и ограничения бесплатных ресурсов Render могут меняться. Перед production-развёртыванием проверьте актуальные условия хранения и резервного копирования PostgreSQL в документации Render.

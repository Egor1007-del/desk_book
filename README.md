# Desk Book

[![Ruby](https://img.shields.io/badge/Ruby-4.0.6-CC342D.svg)](https://www.ruby-lang.org/)
[![Rails](https://img.shields.io/badge/Rails-8.1.3.1-D30001.svg)](https://rubyonrails.org/)
[![PostgreSQL](https://img.shields.io/badge/production-PostgreSQL-4169E1.svg)](https://www.postgresql.org/)
[![Hotwire](https://img.shields.io/badge/UI-Hotwire-5A00FF.svg)](https://hotwired.dev/)

Desk Book — двуязычный справочник сотрудников организации на Ruby on Rails. Приложение объединяет реестр сотрудников, ролевое управление, личный профиль, административную аналитику и XLSX-выгрузку. Интерфейс использует Turbo и Stimulus для точечных обновлений без отдельного SPA.

**Live demo:** [https://desk-book.onrender.com](https://desk-book.onrender.com)

Production credentials не публикуются. Бесплатный Web Service может запускаться около минуты после простоя.

## Возможности

### Сотрудник

- вход по логину и паролю без публичной регистрации;
- просмотр реестра и карточек сотрудников;
- просмотр реестра с серверной пагинацией по 10 записей;
- просмотр ФИО, должности, даты приёма, телефона и email;
- изменение собственного логина, пароля, телефона и email;
- выгрузка полного реестра в XLSX;
- переключение русского и английского интерфейса.

### Администратор

- полный CRUD сотрудников;
- назначение ролей `admin` и `employee`;
- управление логинами и установка новых паролей;
- Turbo Frame-формы внутри реестра;
- обновление таблицы, счётчика, пагинации и flash-сообщений через Turbo Streams;
- аналитика по должностям с пятью последними принятыми сотрудниками;
- защита от удаления или понижения последнего администратора.

Пароли никогда не отображаются: Devise хранит только необратимый хеш. Авторизация выполняется на сервере через Pundit, а не только скрытием элементов интерфейса.

## Технологии

| Область | Решение |
|---|---|
| Backend | Ruby 4.0.6, Rails 8.1.3.1 |
| Базы данных | SQLite в development/test, PostgreSQL в production |
| Аутентификация | Devise, вход по `login` |
| Роли и права | Rolify, Pundit |
| Представления | Slim, Simple Form |
| Интерфейс | Bootstrap 5, SCSS, Turbo, Stimulus |
| JavaScript | Importmap без отдельного JS bundler |
| Пагинация | Pagy |
| Экспорт | caxlsx, caxlsx_rails |
| Тестирование | Minitest, Capybara, Selenium |
| Проверки | RuboCop, Brakeman, Bundler Audit |
| Production | Docker, Thruster, Puma, Render Blueprint |

## Архитектура

Сотрудник и пользователь системы представлены одной моделью `User`. Должность хранится в `Position`, а глобальная роль назначается через Rolify. Сохранение пользователя и роли выполняется одной транзакционной операцией, поэтому частично созданный пользователь без роли не остаётся в базе.

Браузерные контроллеры находятся в namespace `Web`. Административные контроллеры дополнительно выделены в `Web::Admin`, но публичные URL остаются обычными `/users`, `/profile/edit` и `/admin/...`. Каждый прикладной web-запрос проходит аутентификацию Devise и явную проверку Pundit.

```text
Browser
  │
  ├── Turbo Drive / Frames / Streams
  ├── Stimulus и Bootstrap
  │
  ▼
Web controllers ── Pundit policies
  │
  ▼
User / Position / Role
  │
  ├── SQLite (development, test)
  └── PostgreSQL (production)
```

Turbo Frame загружает административную форму в отдельную область реестра. После сохранения Turbo Stream обновляет несколько DOM-целей одним ответом. Stimulus отвечает только за локальное браузерное поведение: закрытие встроенной формы и автоматическое удаление flash-сообщений.

## Быстрый запуск

### Требования

- Ruby 4.0.6;
- Bundler;
- Node.js и Yarn 1.x для сборки Bootstrap SCSS;
- SQLite;
- Chrome или Chromium для системных тестов.

Клонируйте репозиторий и подготовьте приложение:

```bash
git clone https://github.com/Egor1007-del/desk_book.git
cd desk_book
bin/setup --skip-server
bin/rails db:seed
bin/dev
```

Приложение будет доступно по адресу [http://localhost:3000](http://localhost:3000).

`bin/setup` устанавливает Ruby- и JavaScript-зависимости, подготавливает SQLite и очищает временные файлы. `bin/dev` одновременно запускает Rails и наблюдение за SCSS через `Procfile.dev`.

## Демонстрационные данные

На новой базе `bin/rails db:seed` создаёт:

- три обязательные должности;
- роли `admin` и `employee`;
- первоначального администратора;
- 30 сотрудников, по 10 на каждую должность.

Локальные учебные данные:

| Роль | Логин | Пароль |
|---|---|---|
| Администратор | `admin` | `admin` |
| Сотрудник | `employee01`–`employee30` | `employee` |

Эти значения предназначены только для локального знакомства с проектом. Для собственного запуска их можно переопределить:

```bash
ADMIN_LOGIN=admin \
ADMIN_PASSWORD=change-me-now \
EMPLOYEE_PASSWORD=change-employee-password \
bin/rails db:seed
```

Seeds идемпотентны: повторный запуск с теми же логинами не создаёт дубликаты и не перезаписывает пароль или изменённые данные существующих пользователей. Исключение — обязательная роль первоначального администратора: seed восстановит её, если она отсутствует. Новое значение `ADMIN_LOGIN` создаёт другого администратора, а не переименовывает существующего.

## Переменные окружения

| Переменная | Назначение |
|---|---|
| `ADMIN_LOGIN` | Логин первоначального администратора |
| `ADMIN_PASSWORD` | Пароль администратора при первом создании |
| `EMPLOYEE_PASSWORD` | Пароль демонстрационных сотрудников при первом создании |
| `DATABASE_URL` | Подключение production-приложения к PostgreSQL |
| `RAILS_MASTER_KEY` | Расшифровка Rails credentials в production |
| `RAILS_MAX_THREADS` | Размер пула потоков Puma и подключений к базе |
| `WEB_CONCURRENCY` | Число процессов Puma |
| `PORT` | Внешний порт, предоставленный платформой Render |
| `POSTGRES_PASSWORD` | Пароль локальной PostgreSQL в Docker Compose |

Проект не загружает `.env` автоматически. Не добавляйте `.env`, `config/master.key`, production credentials и рабочие базы в Git.

## Проверки

Основные команды:

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
bundle exec bundler-audit check --update
```

Полный локальный pipeline Rails можно запустить одной командой:

```bash
bin/ci
```

Он подготавливает окружение, проверяет стиль Ruby, зависимости, Importmap, безопасность, обычные и системные тесты, а затем выполняет seeds в тестовой базе.

## Docker

Для production-подобного локального запуска нужны Docker Engine, Docker Compose и существующий `config/master.key`:

```bash
RAILS_MASTER_KEY="$(cat config/master.key)" \
ADMIN_LOGIN=admin \
ADMIN_PASSWORD=change-me-now \
EMPLOYEE_PASSWORD=change-employee-password \
docker compose up --build
```

Compose собирает многоэтапный production-образ, запускает Rails и PostgreSQL 17, применяет миграции и seeds, затем открывает приложение на [http://localhost:3000](http://localhost:3000).

Полезные команды:

```bash
docker compose ps
docker compose logs -f web
docker compose exec web bin/rails console
docker compose down
```

`docker compose down` удаляет контейнеры и сеть, но сохраняет PostgreSQL в именованном volume `postgres_data`. Следующая команда удалит и volume вместе со всеми локальными production-подобными данными:

```bash
docker compose down --volumes
```

Не выполняйте её, если данные нужны.

Финальный контейнер работает от непривилегированного пользователя. Node.js, Yarn, компиляторы и заголовочные файлы PostgreSQL остаются только на build-стадии и не попадают в runtime-образ.

## Render

Проект подготовлен для Docker-деплоя через [`render.yaml`](render.yaml). Blueprint описывает:

- Docker Web Service `desk-book`;
- управляемую PostgreSQL `desk-book-db`;
- автоматическую передачу `DATABASE_URL`;
- health check `/up`;
- секреты `RAILS_MASTER_KEY`, `ADMIN_LOGIN`, `ADMIN_PASSWORD` и `EMPLOYEE_PASSWORD`.

Порядок первого деплоя:

1. Отправить актуальную ветку `main` в GitHub.
2. В Render выбрать **New → Blueprint** и подключить репозиторий.
3. Подтвердить ресурсы из `render.yaml`.
4. Ввести `RAILS_MASTER_KEY` из локального `config/master.key`.
5. Задать production-значения `ADMIN_LOGIN`, `ADMIN_PASSWORD` и `EMPLOYEE_PASSWORD`.
6. Дождаться сборки образа, миграций, seeds и успешного health check `/up`.

Docker Compose на Render не запускается. Render собирает корневой [`Dockerfile`](Dockerfile), создаёт PostgreSQL отдельно и передаёт приложению `DATABASE_URL`. Production-данные не хранятся внутри заменяемого Rails-контейнера.

Проверенный deployment доступен по адресу [https://desk-book.onrender.com](https://desk-book.onrender.com). Бесплатный Web Service засыпает после 15 минут без входящего трафика, а бесплатная PostgreSQL истекает через 30 дней и не предоставляет резервные копии. Для постоянного размещения базу нужно перевести на платный план до истечения этого срока.

## Основные маршруты

| URL | Назначение |
|---|---|
| `/users/sign_in` | Публичная форма входа |
| `/` | Главная страница после входа |
| `/users` | HTML-реестр сотрудника; администратора перенаправляет в `/admin/users` |
| `/users.xlsx` | Полная XLSX-выгрузка для обеих ролей |
| `/users/:id` | Карточка сотрудника |
| `/profile/edit` | Личный профиль текущего пользователя |
| `/admin/users` | Административный реестр и CRUD |
| `/admin/analytics` | Аналитика по должностям |
| `/up` | Health check Rails |

Прикладные HTML-страницы доступны только после аутентификации. Исключения — форма входа и публичный health check `/up`. Права на конкретное действие зависят от роли пользователя.

## Структура проекта

```text
app/controllers/web/       web- и административные контроллеры
app/javascript/controllers Stimulus-контроллеры
app/models/                модели и транзакционные правила
app/policies/              политики Pundit
app/views/                 Slim, Turbo Frame и Turbo Stream шаблоны
config/locales/            русские и английские переводы
db/seeds.rb                идемпотентные демонстрационные данные
test/                      модельные, policy, интеграционные и system tests
Dockerfile                 production-образ
docker-compose.yml         локальные Rails и PostgreSQL
render.yaml                Render Blueprint
```

## Безопасность демонстрационного проекта

- публичная регистрация и восстановление пароля отключены;
- пароль не хранится и не выводится в открытом виде: в базе находится только его необратимый хеш;
- Pundit проверяет каждое прикладное действие на сервере;
- strong parameters ограничивают изменяемые поля;
- последнего администратора нельзя удалить или понизить;
- deployment-секреты передаются через окружение, а зашифрованные Rails credentials открываются только с `RAILS_MASTER_KEY`;
- Brakeman и Bundler Audit входят в набор проверок.

Учебные пароли нужны для локальной демонстрации и должны быть заменены перед любым внешним развёртыванием.

# Прогресс реализации

## Завершённые этапы

- Этап 1. Проверены и зафиксированы версии среды: Ruby 4.0.6 и Rails 8.1.3.1.
- Этап 2. В текущем каталоге создано приложение `desk_book` с SQLite, Importmap, Turbo, Stimulus, Bootstrap 5 и SCSS через cssbundling-rails.
- Этап 3. Git-репозиторий инициализирован, Rails-каркас проверен и включён в начальный тематический коммит.
- Этап 4. Подключён Slim, начальные ERB-шаблоны преобразованы в Slim и проверены реальным рендерингом Rails.
- Этап 5. Проверена конфигурация Bootstrap и SCSS, подключён Simple Form 5.4.1 с Bootstrap 5 wrappers и Slim-шаблоном scaffold-формы.

## Текущий этап

- Активного этапа нет. Этап 6 ещё не начат и ожидает отдельного подтверждения пользователя.

## Основные изменённые файлы

- `TASK.md` — восстановлена первоначальная формулировка пункта 7.
- `docs/IMPLEMENTATION_SPEC.md` — зафиксировано позднее согласованное дополнение к пункту 7 исходного задания.
- `docs/LEARNING_NOTES.md` — добавляются подробные учебные объяснения назначения этапов и ответы на вопросы пользователя о проекте.
- `Gemfile` и `Gemfile.lock` — Rails зафиксирован строго на версии 8.1.3.1, добавлены `slim-rails` и development-зависимость `blueprint-html2slim` 1.3.x.
- `.ruby-version` — зафиксирован Ruby 4.0.6.
- `package.json` и `yarn.lock` — зафиксированы зависимости сборки Bootstrap SCSS.
- `app/views/layouts/*.slim` и `app/views/pwa/manifest.json.slim` — заменили начальные ERB-шаблоны.
- `config/initializers/simple_form.rb` и `config/initializers/simple_form_bootstrap.rb` — настроены Simple Form и Bootstrap 5 wrappers.
- `config/locales/simple_form.en.yml` и `lib/templates/slim/scaffold/_form.html.slim` — добавлены локаль и Slim-шаблон форм генератора.
- `config/initializers/assets.rb` — добавлен отсутствовавший завершающий перевод строки.
- `app/`, `bin/`, `config/`, `db/`, `test/` и остальные стандартные файлы Rails — создан базовый каркас приложения.
- `Dockerfile` и `.dockerignore` — созданы генератором Rails без проектной адаптации.

## Выполненные проверки

- `ruby -v` — Ruby 4.0.6.
- `which ruby` — `/home/egor/.rvm/rubies/ruby-4.0.6/bin/ruby`.
- `bin/rails -v` — Rails 8.1.3.1 после строгой фиксации версии в `Gemfile`.
- `bundle check` — все зависимости `Gemfile` установлены.
- `yarn check --integrity` — каталог JavaScript-зависимостей синхронизирован с `yarn.lock`.
- `yarn build:css` — Bootstrap CSS собран успешно.
- `bin/rails test` — 0 ошибок и 0 падений; тесты приложения ещё не добавлены.
- `bundle exec slimtool validate` — четыре Slim-шаблона валидны, ошибок нет.
- Основной Slim layout успешно отрендерен через `ApplicationController.render`.
- Slim-шаблон PWA manifest успешно отрендерен и разобран через `JSON.parse`.
- `bin/rubocop` — 24 файла проверены, нарушений нет.
- `git diff --check` — форматных ошибок нет.
- Simple Form 5.4.1 загружается с wrapper `vertical_form` по умолчанию.
- Smoke-проверка Simple Form отрендерила Bootstrap-классы `form-control` и `mb-3`.
- `yarn build:css` — Bootstrap SCSS успешно собран после настройки Simple Form.
- `git check-ignore` — `config/master.key`, `node_modules` и рабочие SQLite-файлы исключены из Git.
- `AGENTS.md`, `TASK.md`, `docs/IMPLEMENTATION_SPEC.md` и `docs/PROGRESS.md` сохранены.

## Важные решения

- Название приложения и текущий каталог остаются `desk_book`.
- `TASK.md` хранит первоначальное задание; позднее согласованные дополнения хранятся в `docs/IMPLEMENTATION_SPEC.md` и имеют приоритет.
- Ruby 4.0.6 выбирается только для текущей оболочки; RVM default не изменён.
- Стандартное ограничение генератора Rails допускало Rails 8.1.4, поэтому `Gemfile` изменён на точную версию 8.1.3.1.
- Несовместимый с Ruby 4.0.6 гем `html2slim` заменён согласованным `blueprint-html2slim` 1.3.x; решение зафиксировано в `docs/IMPLEMENTATION_SPEC.md`.
- Все новые представления следует писать на Slim.
- Перед этапом не перечисляются планируемые команды и возможные изменения; после завершения этапа его подробное назначение, а также ответы на учебные вопросы добавляются в `docs/LEARNING_NOTES.md`.
- Simple Form использует сгенерированные Bootstrap 5 wrappers; валидации данных по-прежнему реализуются в моделях Rails.

## Текущие блокеры

- RVM в обычном исполнителе команд загружается не как shell-функция; для временного переключения используется login-shell.
- RubyGems выводит предупреждения о одновременно загруженных RDoc 7.0.4 и 8.0.0. Они намеренно не исправлялись.
- CLI `blueprint-html2slim` 1.3.1 выводит устаревшую внутреннюю строку версии `html2slim 1.1.0`; фактическая версия 1.3.1 зафиксирована в `Gemfile.lock`.

## Следующий шаг

- Представить план этапа 6 «Создать Position и User с индексами, inverse_of и тестами» и дождаться подтверждения пользователя.

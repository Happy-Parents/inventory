# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Rails 8.1 (Ruby 3.4.8) inventory management app: an ActiveAdmin 4 (beta, Tailwind-based) back office over products, brands, categories, warehouses, and stock items, backed by PostgreSQL 17. There is no public UI — `/` redirects to `/admin`. Cache/jobs/cable are database-backed (solid_cache, solid_queue, solid_cable).
Root project ingrastructure homedirectory is ../
Whole project is:
../application - current project, main application.
../wiki - application documentation.
../active_admin_configurable_columns - connected gem.

## Genral instuctions

* follow SOLID, KISS, YAGNI and Clean Architecture principles.
* Comments: Add comments only in critical sections. Keep them concise and focused on the core business logic rather than technical implementation details.

## Commands

Development normally runs in Docker (`docker compose up`); prefix commands with `docker compose exec web` in that case. Locally, `bin/setup` then `bin/dev` (foreman: Puma + ActiveAdmin Tailwind watcher — without the watcher the admin renders unstyled).

```bash
bundle exec rspec                          # test suite (RSpec, not minitest)
bundle exec rspec spec/models/admin_spec.rb         # one file
bundle exec rspec spec/models/admin_spec.rb:12      # one example
bin/rubocop                                # lint (omakase + enforced single quotes)
bin/brakeman                               # security static analysis
bin/bundler-audit                          # vulnerable gems
bin/importmap audit                        # JS dependency audit
bin/rails db:prepare                       # create/migrate
bin/rails db:seed                          # sample data
bin/rails inventory:import                 # import data_source/inventory-state.csv (override: CSV_PATH=...)
```

- The real test suite is **RSpec under `spec/`**. The `test/` directory is empty minitest scaffolding, and `bin/ci` / `config/ci.rb` still run `bin/rails test` — don't rely on them; run the commands above individually.
- `app/assets/tailwind/active_admin.css` build output is gitignored, so request specs that render admin pages need `bin/rails active_admin:tailwind:build` run once first (CI does this).
- Overcommit git hooks mirror CI: pre-push runs RuboCop, bundler-audit, and the full RSpec suite. GitHub Actions (`.github/workflows/ci.yml`) runs the same plus Brakeman and the importmap audit; all four job checks are required to merge to `main` (see `docs/ci.md` — renaming a CI job breaks the branch ruleset).
- Postgres connection is configured via `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD` (defaults: `localhost:5432`, role `hp_inventory`). In Docker, the DB is reachable from the host on port 5433.

## Architecture

**Everything is ActiveAdmin.** Resources and pages live in `app/admin/` (products, brands, categories, warehouses, stock_items, admins, dashboard, my_account). Outside the API (below) there are no conventional resource controllers — the only other custom controllers are `Admins::OmniauthCallbacksController` and `RobotsController`. Column visibility on index pages comes from the `activeadmin_configurable_columns` gem, configured per-admin on the My Account page.

**Domain model:** `Product` belongs to `Brand` and `Category` (both optional); `StockItem` is the join between `Product` and `Warehouse` (unique per product+warehouse pair, tracks `quantity` and `damaged_quantity`); `Category` is self-referential (parent/subcategories). Primary keys are UUIDs. Model files carry schema annotations maintained by annotaterb.

**Authentication** (Devise on the `Admin` model): there is no sign-up — admins are provisioned in advance. Three OmniAuth providers:
- Google and GitHub sign-in resolve an *existing* admin by email (`ResolveAdminByEmail`); unknown emails are rejected.
- Telegram uses a custom strategy (`lib/omniauth/strategies/telegram.rb`, Telegram Login Widget with HMAC validation). The same callback either signs in a linked admin or, when already signed in, links Telegram to the current account from My Account.

**Authorization** is two-layered:
- `InventoryAuthorization` (`app/policies/inventory_authorization.rb`) is the ActiveAdmin authorization adapter. Roles on `Admin`: `super_admin` manages everything including Admin records; `manager` manages everything *except* Admin records (may view their own profile).
- Pundit policies in `app/policies/` (tested with pundit-matchers).

**JSON API** (for the mobile app, see the wiki page `../wiki/JSON-API.md`): controllers under `app/controllers/api/v1/` inherit `Api::V1::BaseController` (`ActionController::API` — no cookies/CSRF; Pundit with `verify_authorized`; errors rendered as `{ error: { code, message } }`; resources serialized with Blueprinter blueprints in `app/blueprints/api/v1/`). Auth: stateless 15-min JWT access tokens (`app/interactions/api_access_token.rb`) plus rotating, DB-backed refresh tokens (`ApiSession`, digests only, reuse revokes the session). Routes live in `namespace :api / :v1` in `config/routes.rb`. OpenAPI docs are generated by rswag from `spec/requests/api/**` into `swagger/v1/openapi.yaml` (`RAILS_ENV=test bin/rails rswag:specs:swaggerize`; CI fails if stale), served at `/api/v1/openapi.yaml`, Swagger UI at `/api/v1/docs`.

**Service layer:** business operations are plain classes in `app/interactions/` that `extend Callable` (`app/interfaces/callable.rb`), invoked as `SomeInteraction.call(...)` and returning DTOs from `app/dto/`.

**Interaction naming:** an interaction's name is a verb phrase answering "what to do?", namespaced under the entity it acts on — `<Namespace>::<Verb>`, never a noun (`ApiAccessToken::Decode`, not `ApiAccessToken::Decoder`) and never with the entity folded into the name (`ApiSessions::Refresh`, not `RefreshApiSession`). The namespace is always a plain `module`, never an ActiveRecord model: interactions must not be nested inside model classes (a constant can't be both, and it keeps operations out of the persistence layer). For an entity backed by a model, use the model's plural (`module ApiSessions` for `ApiSession`); for a concept without a model, the singular (`module ApiAccessToken`). Files follow the namespace: `app/interactions/api_sessions/refresh.rb`, spec in `spec/interactions/api_sessions/refresh_spec.rb`. Inside the namespace, refer to sibling interactions unqualified (`CreateTokenPair.call`) and to the model fully (`ApiSession.digest`). `ConnectTelegram`, `ResolveAdminByEmail` and `ResolveAdminByTelegram` predate this rule.

**Custom errors:** every custom error class lives in its own file under `app/errors/`, with the path mirroring its namespace (`app/errors/api_sessions/invalid_refresh_token.rb` → `ApiSessions::InvalidRefreshToken`). Never nest an error inside another class or define it inline (`Invalid = Class.new(StandardError)`); namespaces are modules, as for interactions, and code inside the namespace raises the error by its short name. Errors raised by version-agnostic interactions stay in their domain namespace (`ApiAccessToken::Invalid`); errors specific to an API version go under `app/errors/api/v1/` as `Api::V1::...`, one file per class.

**Shared model concerns:** `Ransackable` (models whitelist search attributes via `unransackable_attributes`) and `TranslatableEnum` (human-readable enum labels via i18n).

**i18n:** default locale is `:uk` (available: `:uk`, `:en`). User-facing strings go through `I18n.t`; i18n-tasks is available to check for missing/unused keys. The CSV import task maps Ukrainian column headers.

**Testing:** RSpec with FactoryBot (`spec/factories/`), Faker, shoulda-matchers, and Bullet enabled (N+1 queries fail specs). `.rspec` auto-requires `rails_helper`.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Rails 8.1 (Ruby 3.4.8) inventory management app: an ActiveAdmin 4 (beta, Tailwind-based) back office over products, brands, categories, warehouses, and stock items, backed by PostgreSQL 17. There is no public UI — `/` redirects to `/admin`. Cache/jobs/cable are database-backed (solid_cache, solid_queue, solid_cable).
Root project ingrastructure homedirectory is ../
Whole project is:
../application - current project, main application.
../wiki - application documentation.
../active_admin_configurable_columns - connected gem.

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

**Everything is ActiveAdmin.** Resources and pages live in `app/admin/` (products, brands, categories, warehouses, stock_items, admins, dashboard, my_account). There are no conventional resource controllers — the only custom controllers are `Admins::OmniauthCallbacksController` and `RobotsController`. Column visibility on index pages comes from the `activeadmin_configurable_columns` gem, configured per-admin on the My Account page.

**Domain model:** `Product` belongs to `Brand` and `Category` (both optional); `StockItem` is the join between `Product` and `Warehouse` (unique per product+warehouse pair, tracks `quantity` and `damaged_quantity`); `Category` is self-referential (parent/subcategories). Primary keys are UUIDs. Model files carry schema annotations maintained by annotaterb.

**Authentication** (Devise on the `Admin` model): there is no sign-up — admins are provisioned in advance. Three OmniAuth providers:
- Google and GitHub sign-in resolve an *existing* admin by email (`ResolveAdminByEmail`); unknown emails are rejected.
- Telegram uses a custom strategy (`lib/omniauth/strategies/telegram.rb`, Telegram Login Widget with HMAC validation). The same callback either signs in a linked admin or, when already signed in, links Telegram to the current account from My Account.

**Authorization** is two-layered:
- `InventoryAuthorization` (`lib/inventory_authorization.rb`) is the ActiveAdmin authorization adapter. Roles on `Admin`: `super_admin` manages everything including Admin records; `manager` manages everything *except* Admin records (may view their own profile).
- Pundit policies in `app/policies/` (tested with pundit-matchers).

**Service layer:** business operations are plain classes in `app/interactions/` that `extend Callable` (`app/interfaces/callable.rb`), invoked as `SomeInteraction.call(...)` and returning DTOs from `app/dto/`.

**Shared model concerns:** `Ransackable` (models whitelist search attributes via `unransackable_attributes`) and `TranslatableEnum` (human-readable enum labels via i18n).

**i18n:** default locale is `:uk` (available: `:uk`, `:en`). User-facing strings go through `I18n.t`; i18n-tasks is available to check for missing/unused keys. The CSV import task maps Ukrainian column headers.

**Testing:** RSpec with FactoryBot (`spec/factories/`), Faker, shoulda-matchers, and Bullet enabled (N+1 queries fail specs). `.rspec` auto-requires `rails_helper`.

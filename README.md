# HP Inventory

Rails 8 inventory management app: an ActiveAdmin back office over products,
brands, categories, warehouses, and stock items, backed by PostgreSQL.

| | |
|---|---|
| Ruby | 3.4.8 (`.ruby-version`) |
| Rails | 8.1 |
| Database | PostgreSQL 17 |
| Assets | Propshaft + importmap, Tailwind (ActiveAdmin) |
| Cache / jobs / cable | solid_cache, solid_queue, solid_cable (database-backed) |

The app has no public UI of its own: `/` redirects to `/admin`.

---

## Development with Docker

Everything is prepared by the images -- Ruby, Postgres, and the gems -- so
Docker is the only prerequisite.

```bash
docker compose build
docker compose up
```

Then open <http://localhost:3000> (redirects to `/admin`).

The first `up` creates and migrates `hp_inventory_development`; on later boots
it applies pending migrations. To load sample data:

```bash
docker compose exec web bin/rails db:seed
```

### What is running

| Service | Role |
|---|---|
| `web` | Puma on port 3000, bind-mounted working tree so edits reload live |
| `admin_css` | `active_admin:tailwind:watch` -- rebuilds `app/assets/tailwind/active_admin.css`; without it the admin renders unstyled |
| `db` | PostgreSQL 17, data in the `postgres` named volume, published on host port 5433 |

`web` and `admin_css` are the same pair of processes as `Procfile.dev`, one per
container instead of under foreman.

### Everyday commands

```bash
docker compose up -d                       # background
docker compose logs -f web                 # tail logs (also: admin_css, db)
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate
docker compose exec web bin/rails test
docker compose exec web bin/rubocop
docker compose exec web bash               # shell in the app container
docker compose exec db psql -U hp_inventory hp_inventory_development
docker compose down                        # stop; add -v to also drop the database volume
```

Reach the database from the host (TablePlus, psql, ...) on port **5433**:

```bash
psql -h localhost -p 5433 -U hp_inventory hp_inventory_development   # password: hp_inventory
```

Debugging with the `debug` gem works through the TTY that compose keeps open:
put a `debugger` in your code, then `docker compose attach web` and interact
with the prompt there (`Ctrl-P Ctrl-Q` detaches without stopping the server).

### After changing the Gemfile

Gems live in the image, not in a volume, so rebuild:

```bash
docker compose build && docker compose up -d
```

For a quick one-off try, `docker compose exec web bundle install` installs into
the running container -- it is lost on the next `up`, so still rebuild after.

### Configuration

Development needs no environment file: every variable in `compose.yaml` has a
default. To override any of them (ports, Postgres credentials), copy the
template and edit it -- Compose loads `.env` automatically:

```bash
cp .env.example .env
```

Credentials (`config/credentials/development.yml.enc`) work as-is, because the
matching `.key` file comes in over the bind mount.

### Files

| File | Purpose |
|---|---|
| `compose.yaml` | Development stack |
| `Dockerfile.dev` | Development image -- single stage, keeps the build toolchain, installs the development/test gem groups |
| `bin/docker-entrypoint-dev` | Waits for Postgres, syncs the bundle, runs `db:prepare`, clears any stale pidfile |
| `.env.example` | Documented template for both environments |

### Without Docker

A local Ruby 3.4.8 and PostgreSQL also work:

```bash
bin/setup      # bundle install + db:prepare
bin/dev        # foreman: server + tailwind watcher
```

`config/database.yml` defaults to `localhost:5432` with the role
`hp_inventory`; override with `DB_HOST`, `DB_PORT`, `DB_USERNAME`,
`DB_PASSWORD`.

---

## Production with Docker

`Dockerfile` builds the production image: multi-stage, gems without the
development group, assets precompiled in, jemalloc enabled, running as a
non-root user, served by [Thruster](https://github.com/basecamp/thruster) in
front of Puma on port 80.

`compose.production.yaml` runs that image on a single Docker host.

### 1. Configure

```bash
cp .env.example .env.production
```

Fill in at minimum:

- `RAILS_MASTER_KEY` -- the contents of `config/credentials/production.key`
  (`cat config/credentials/production.key`). The key file is excluded from the
  image by `.dockerignore`, so it has to be supplied through the environment.
- `POSTGRES_PASSWORD` -- e.g. `openssl rand -hex 24`.

Keep this file off the repository and off shared machines; it is gitignored.

### 2. Deploy

```bash
docker compose --env-file .env.production -f compose.production.yaml up -d --build
```

Compose refuses to start with a clear error if either secret is missing.

| Service | Role |
|---|---|
| `web` | Thruster + Puma on port 80. Its entrypoint runs `db:prepare` on boot, so migrations apply automatically |
| `jobs` | Solid Queue worker (`bin/jobs`), separate from Puma so a job backlog cannot starve web requests |
| `db` | PostgreSQL 17, not published to the host |

`db:prepare` creates four databases on first boot -- primary, cache, queue, and
cable -- which is why the Postgres role needs `CREATEDB`. See the comment block
in `config/database.yml` for overriding those names on managed hosts.

Health is reported through `/up`; `docker compose -f compose.production.yaml ps`
shows it. Uploads persist in the `storage` volume, database data in `postgres`
-- back both up.

### Operating

```bash
export COMPOSE="docker compose --env-file .env.production -f compose.production.yaml"

$COMPOSE ps
$COMPOSE logs -f web
$COMPOSE exec web bin/rails console
$COMPOSE up -d --build            # deploy a new version
$COMPOSE exec db pg_dump -U hp_inventory hp_inventory_production > backup.sql
```

TLS is not handled here -- put a reverse proxy (Caddy, nginx, Cloudflare) in
front of `WEB_PORT`, and enable `config.assume_ssl` and `config.force_ssl` in
`config/environments/production.rb` once it is in place.

### Other deployment paths

The same production image also runs under
[Kamal](https://kamal-deploy.org) (`config/deploy.yml`), which adds
zero-downtime rollouts and multi-server support:

```bash
bin/kamal setup
bin/kamal deploy
```

Separately, `.cpanel.yml` deploys this app **without** Docker to a cPanel host
running Phusion Passenger, triggered by `git push`. That is the path the
currently hosted instance uses; the Docker setups above do not affect it.

---

## Tests and checks

```bash
docker compose exec web bin/rails test
docker compose exec web bin/rubocop        # Omakase style
docker compose exec web bin/brakeman       # security scan
docker compose exec web bin/bundler-audit  # vulnerable gems
docker compose exec web bin/ci             # everything, as CI runs it
```

GitHub Actions runs the same set on push (`.github/workflows/ci.yml`).

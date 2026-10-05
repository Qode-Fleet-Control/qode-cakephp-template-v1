# CakePHP template

Provisioned from [`Qode-Fleet-Control/fleet-template-v1`](https://github.com/Qode-Fleet-Control/fleet-template-v1) — the fleet
lifecycle contract (`bin/`, `fleet.conf`, `compose.yaml`, deploy workflows) with the
official CakePHP 5 application skeleton laid on top, served by FrankenPHP.

## Origin

    docker run --rm -u $(id -u):$(id -g) -v "$PWD":/w -w /w <php8.4 + composer:2 image> \
      composer create-project cakephp/app qode-cakephp-template-v1 --prefer-dist --no-interaction

Generated 2026-10-05 (cakephp/app, cakephp/cakephp 5.4.*, PHP 8.4.26 — the PHP the image
runs). `vendor/` and the generated `config/app_local.php` (gitignored by the skeleton; it
held a fresh salt) were removed; `composer.lock` is kept.

## Run it

**On the fleet** — nothing to do: `bin/run` (docker runtime) does `docker compose build`
then `docker compose up --remove-orphans` in the foreground. The app listens on
`0.0.0.0:$PORT` (default 8765, CakePHP's own); `HEALTH_PATH=/health`.

`/` is the stock home page, which **throws a 404 unless debug is on** (it says so:
"replace templates/Pages/home.php with your own version or re-enable debug mode"). The
image runs `DEBUG=false` because DebugKit is a dev-only package left out of the image.

**With docker**

    PORT=8765 bin/run              # or: docker compose up --build
    curl localhost:8765/health

**Without docker** (PHP 8.2+ with intl and mbstring, composer):

    FLEET_RUNTIME=process PORT=8765 bin/run
    # = composer install (writes config/app_local.php with a fresh salt, debug on);
    #   bin/cake server -H 0.0.0.0 -p $PORT

| step | process runtime | docker runtime |
|---|---|---|
| install | `composer install --no-interaction` | — |
| build | — | `docker compose build` |
| start | `bin/cake server -H 0.0.0.0 -p $PORT` | `docker compose up --remove-orphans` |

`bin/cake` is CakePHP's own console; it lives in `bin/` beside the fleet scripts.

## How the container works

- `Dockerfile`: `dunglas/frankenphp:1-php8.4-bookworm` (+ intl, pdo_pgsql, pdo_mysql,
  zip), `composer install --no-dev`, non-root user `app` owning `tmp/` and `logs/`.
- `docker/entrypoint.sh`: generates a `SECURITY_SALT` when none is set (set it to keep
  it stable), defaults `APP_FULL_BASE_URL` to `$FLEET_APP_URL`, then serves with
  FrankenPHP's stock Caddyfile on `SERVER_NAME=":$PORT"`, document root `webroot/`.
- Database: `config/app.php` already reads `DATABASE_URL` (`Datasources.default.url`),
  so the fleet's Postgres is used as soon as it is injected.

## Deviations from the stock generator output, and why

- `src/Controller/HealthController.php` + a `/health` route in `config/routes.php`
  returning `{"status":"ok"}` — the fleet's health check (`/` is a 404 in production).
- Added `Dockerfile`, `docker/entrypoint.sh`, `compose.yaml`, `.dockerignore`,
  `fleet.conf`, the fleet scripts in `bin/`, `.github/workflows/deploy.yml` and
  `manual-deploy.yml` (beside the skeleton's own `ci.yml`/`stale.yml`),
  `docs/fleet-lifecycle.md`; `.gitignore` gained `.fleet/`, `.fleet-deploy.log`, `*.log`.

## Verified

**Not verified yet.** The `docker compose build` / `verify.sh` run was never reached: on
2026-10-05 the shared docker host's disk sat at 0-2 GB free (98 GB volume at 99-100%)
for more than three hours, below the 6 GB gate builds wait for. Before trusting this
template, run `verify.sh <dir> <port>` (run, restart and stop must all pass).

What *was* checked: `migrate.py audit` → READY; `php -l` on every PHP file this template
added or changed, and `sh -n` on its shell scripts → clean.

See `docs/fleet-lifecycle.md` for the lifecycle scripts.

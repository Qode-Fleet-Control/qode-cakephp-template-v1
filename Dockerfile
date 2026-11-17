# Built by .github/workflows/deploy.yml (context ., file Dockerfile) and pushed
# to Artifact Registry.
#
# CakePHP 5 app on FrankenPHP (a Caddy-based PHP app server): docroot webroot/,
# DEBUG=false, served on 0.0.0.0:$PORT with the PORT read from the environment when
# the container STARTS (docker/entrypoint.sh).
FROM dunglas/frankenphp:1-php8.4-bookworm AS runtime
RUN install-php-extensions intl pdo_pgsql pdo_mysql zip
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY . .
RUN composer dump-autoload --optimize --no-dev --no-interaction \
 && useradd -r -u 10001 -d /app app \
 && mkdir -p tmp/cache/models tmp/cache/persistent tmp/cache/views tmp/sessions tmp/tests logs && chown -R app:app tmp logs /config/caddy /data/caddy \
 && chmod +x docker/entrypoint.sh
# KEEP THIS: one log line per request (status + duration) is what the workspace Monitoring tab charts.
# docker/request-log.caddyfile turns on Caddy's JSON access log on stdout; the stock Caddyfile
# imports it into its site block through CADDY_SERVER_EXTRA_DIRECTIVES.
COPY docker/request-log.caddyfile /etc/frankenphp/request-log.caddyfile
ENV CADDY_SERVER_EXTRA_DIRECTIVES="import /etc/frankenphp/request-log.caddyfile"
ARG BUILD_ID=""
ENV PORT=8765 SERVER_ROOT=/app/webroot DEBUG=false BUILD_ID=$BUILD_ID
USER app
EXPOSE 8765
ENTRYPOINT ["docker/entrypoint.sh"]

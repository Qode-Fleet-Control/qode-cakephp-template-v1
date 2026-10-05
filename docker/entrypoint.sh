#!/bin/sh
# Container start: serve the CakePHP app on 0.0.0.0:$PORT.
set -e

# config/app_local.php (which carries the salt) is gitignored, so the image has none:
# without SECURITY_SALT from the environment, make one for this container.
if [ -z "${SECURITY_SALT:-}" ]; then
  SECURITY_SALT="$(php -r 'echo bin2hex(random_bytes(32));')"
  export SECURITY_SALT
  echo "entrypoint: SECURITY_SALT was empty; generated one for this container"
fi
# Absolute links use the fleet's public URL.
if [ -z "${APP_FULL_BASE_URL:-}" ] && [ -n "${FLEET_APP_URL:-}" ]; then
  export APP_FULL_BASE_URL="$FLEET_APP_URL"
fi

export SERVER_NAME=":${PORT:-8765}"
exec frankenphp run --config /etc/frankenphp/Caddyfile

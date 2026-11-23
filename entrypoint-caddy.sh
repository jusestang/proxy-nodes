#!/bin/sh
# Caddy variant entrypoint: fills configs from env, starts sing-box in the
# background, runs Caddy in the foreground on $PORT.
set -e
PORT="${PORT:-8080}"
UUID="${UUID:?UUID env var is required}"
WS_PATH="${WS_PATH:-/ws}"
sed -i "s/__UUID__/$UUID/; s#__WS_PATH__#$WS_PATH#g" /etc/sing-box/config.json
sed -i "s/{\$PORT}/$PORT/; s#{\$WS_PATH}#$WS_PATH#g" /etc/caddy/Caddyfile
sing-box run -c /etc/sing-box/config.json &
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile

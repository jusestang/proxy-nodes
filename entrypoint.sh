#!/bin/sh
# Fills the sing-box config from env vars, then runs it.
# Required: UUID (one per node, e.g. uuidgen). Optional: PORT (default 8080),
# WS_PATH (default /ws).
set -e
PORT="${PORT:-8080}"
UUID="${UUID:?UUID env var is required}"
WS_PATH="${WS_PATH:-/ws}"
sed -i "s/__PORT__/$PORT/; s/__UUID__/$UUID/; s#__WS_PATH__#$WS_PATH#g" /etc/sing-box/config.json
exec sing-box run -c /etc/sing-box/config.json

# Proxy nodes on the 7 free tiers — deploy notes

Shared design: **VLESS over WebSocket, TLS terminated by the platform**.
Every platform below exposes your service through its own HTTPS reverse
proxy, so the client connects to `https://<platform-domain>` on port 443
and the proxy traffic rides inside a WebSocket. sing-box itself runs
without TLS. One UUID per node (generate with `uuidgen`).

Client link (v2rayNG scans this as a QR code — see `gen-qr.py`):
`vless://UUID@HOST:443?encryption=none&security=tls&type=ws&path=%2Fws&host=HOST&sni=HOST#NAME`

## Per-platform deploy

### 1. Cloady — BEST, only one with raw TCP (IPv6-only)
- Deploy: GitHub repo (Railpack/Dockerfile), Docker image, folder upload, CLI, API.
- Public endpoint: `https://<app>-<code>-<workspace>.cloady.io` (HTTPS) **and**
  raw TCP/UDP ports published over IPv6: in a compose file add
  `"443:443/tcp"` and connect to the app's IPv6 address. Raw TCP means a
  native VLESS/Trojan node (no WebSocket needed) — but the client must
  have IPv6. For the WS variant use the shared Dockerfile with `PORT=8080`.
- Free: 0.5 vCPU / 1 GB RAM / 5 GB SSD per workspace, 10 GB outbound/mo
  (docs). Web-UI image deploy cannot set the port — use a Dockerfile via
  upload/GitHub, or `cloady deploy ... --port 8080`.
- ⚠️ Verify: docs describe a permanent free workspace, but Nov 2026
  reports say new accounts may be limited to one month free; check the
  billing page. Also verify whether the HTTPS endpoint has IPv4 (docs
  only mention an AAAA record).

### 2. Uberspace — most flexible, always-on, but not free after month 1
- SSH in, download the sing-box binary, run as a user systemd service,
  expose via web backend:
  ```
  curl -fsSL -o /tmp/sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v1.11.0/sing-box-1.11.0-linux-amd64.tar.gz
  tar -xzf /tmp/sb.tar.gz -C /tmp && cp /tmp/sing-box-1.11.0-linux-amd64/sing-box ~/bin/sing-box
  # write ~/sing-box/config.json (VLESS-WS, listen 0.0.0.0:PORT, port 1024-65535)
  uberspace service add sing-box "$HOME/bin/sing-box run -c $HOME/sing-box/config.json"
  uberspace web backend add / port <PORT> --force   # https://<user>.uber.space
  ```
- No sleep, no hour cap, WebSockets OK (send keepalive: idle HTTP
  connections close after 3 min). No public IP — HTTP(S) via the web
  backend only, so VLESS-WS, not raw TCP.
- Cost: first month free, then pay-what-you-want (suggested €6/9/12).

### 3. ZevCloud — best free always-on PaaS
- Deploy: Add Service → Web Application → GitHub repo with the shared
  Dockerfile (or its own Dockerfile). Set Port (e.g. 8080) and env
  `UUID`, `WS_PATH=/ws`. Public URL: `https://<slug>.zevcloud.app`.
- Free: 512 MB / 1 CPU / 1 GB storage, bandwidth unmetered per docs,
  **no idle shutdown** ("runs until you delete it"), 5 free services/team.
  First free deploy asks for a one-time phone verification.
- VLESS-WS only (HTTPS reverse proxy, no raw TCP documented).

### 4. Hostly — Docker image directly, no Git build
- Deploy: web UI → new service → Docker image. Use a prebuilt image that
  already contains sing-box + config, e.g. build the shared Dockerfile,
  push it to Docker Hub/GHCR, then deploy that image with port 8080 and
  env `UUID`. Or upload a config file (≤1 MB) and mount it at
  `/etc/sing-box/config.json` with the official `ghcr.io/sagernet/sing-box`
  image. Public URL: `https://<service>.<workspace>.hostly.ninja`.
- Free: 1 service per workspace, 50 Core/h + 100 GiB/h + 1 TiB egress per
  30-day workspace period; service pauses at the limit and auto-resumes
  at reset. No sleep documented. No volumes on free tier.
- VLESS-WS only (one public port, HTTPS).

### 5. orkestr — Git → container, sleeps when idle
- Deploy: connect GitHub/GitLab/Bitbucket/Codeberg → New Project → repo
  with the shared Dockerfile (or let it generate one). Public URL:
  `https://<slug>.orkestr.run`. Set env `UUID`, `WS_PATH`, port.
- Free/Starter: 1 project, 1 env, 0.25 vCPU / 512 MB, 300 build min/mo,
  100 GB bandwidth/mo. **Sleeps after 30 min idle**, wakes on next
  request (first connection waits a bit).
- VLESS-WS only. WebSocket upgrade not explicitly documented — test after
  deploy; if WS is blocked, this node won't work.

### 6. Komuta — Git → container, sleeps when idle
- Deploy: connect GitHub/GitLab/Azure DevOps → New App → repo with the
  shared Dockerfile. Public URL:
  `https://<name>-<id>.edge-1.komuta.app` (Germany-East region).
  Define the port on Access & Ports; set env `UUID`, `WS_PATH`.
- Free: 1 service/org, 0.1 vCPU / 256 MB, 450 awake hours/mo,
  **sleeps after 30 min idle**, wakes in ~1 min. $10 welcome credit
  (30 days), 2000 build min/cycle.
- VLESS-WS only (public ingress is HTTPS). WebSocket upgrade not
  explicitly documented — test after deploy.

### 7. Eurobase — weakest for a proxy, needs a wrapper
- No Dockerfile builds (Paketo buildpacks only), containers scale to
  zero, 250 container hours/mo, WS closes after 60 s of silence, every
  response must start within 55 s, health path must answer 2xx/3xx.
- Deploy the `eurobase/` folder as a Node.js project (Node 20/22/24):
  `package.json` build downloads sing-box; `server.js` answers the
  health check and proxies WS to sing-box. Set env `UUID`, `WS_PATH`.
  Keep a keepalive (<60 s) or the WS connection drops.
- VLESS-WS only. Use as a spare node, not the primary.

## Caveats
- No platform here gives a public IPv4 + raw TCP port except Cloady
  (raw TCP over IPv6 only). Everything else is VLESS-over-WebSocket
  through the platform's HTTPS endpoint — that is the only shape that
  works behind these reverse proxies.
- Running a personal proxy may conflict with a platform's acceptable-use
  policy; free tiers can be suspended. Keep traffic personal/light.
- sing-box version is pinned to 1.11.0 in the Dockerfiles; check
  https://github.com/SagerNet/sing-box/releases for a newer one.

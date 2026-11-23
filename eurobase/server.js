// Eurobase wrapper: Eurobase builds with Paketo buildpacks, no Dockerfile.
// This Node server (1) answers GET / with 200 so the health check passes,
// (2) proxies WebSocket upgrades at $WS_PATH to a local sing-box subprocess.
// The build script downloads the sing-box binary at build time into ./bin/.
// The sing-box config is rendered from config.json at runtime (UUID from env).
// Env: PORT (set by Eurobase, default 3000), UUID (required), WS_PATH (/ws).
const http = require('http');
const net = require('net');
const fs = require('fs');
const { spawn } = require('child_process');

const PORT = process.env.PORT || 3000;
const WS_PATH = process.env.WS_PATH || '/ws';
if (!process.env.UUID) { console.error('UUID env var is required'); process.exit(1); }

const rendered = fs.readFileSync('./config.json', 'utf8')
  .replace('__UUID__', process.env.UUID)
  .replace('__WS_PATH__', WS_PATH);
fs.writeFileSync('/tmp/sing-box-config.json', rendered);

const sb = spawn('./bin/sing-box', ['run', '-c', '/tmp/sing-box-config.json'], { stdio: 'inherit' });
sb.on('exit', (code) => { console.error('sing-box exited', code); process.exit(1); });

const server = http.createServer((req, res) => { res.writeHead(200); res.end('ok'); });
server.on('upgrade', (req, socket, head) => {
  if (!req.url.startsWith(WS_PATH)) { socket.destroy(); return; }
  const upstream = net.connect(10000, '127.0.0.1', () => {
    const headers = Object.entries(req.headers).map(([k, v]) => `${k}: ${v}`).join('\r\n');
    upstream.write(`${req.method} ${req.url} HTTP/1.1\r\n${headers}\r\n\r\n`);
    if (head && head.length) upstream.write(head);
    socket.pipe(upstream);
    upstream.pipe(socket);
  });
  upstream.on('error', () => socket.destroy());
  socket.on('error', () => upstream.destroy());
});
server.listen(PORT, '0.0.0.0', () => console.log(`listening on ${PORT}`));

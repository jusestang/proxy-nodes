#!/usr/bin/env python3
"""Build a v2rayNG-importable VLESS link (and QR PNG) for one deployed node.

Usage:
  python3 gen-qr.py --host <domain> --uuid <uuid> [--port 443] [--path /ws]
                    [--name node-name] [--out node.png]

The link format for all PaaS nodes in this repo (TLS terminated by the
platform, WebSocket transport):
  vless://UUID@HOST:443?encryption=none&security=tls&type=ws&path=%2Fws#NAME
QR needs `pip install qrcode[pil]`; without it the script prints the link.
"""
import argparse
import urllib.parse

p = argparse.ArgumentParser()
p.add_argument('--host', required=True)
p.add_argument('--uuid', required=True)
p.add_argument('--port', default='443')
p.add_argument('--path', default='/ws')
p.add_argument('--name', default='node')
p.add_argument('--out')
a = p.parse_args()

q = urllib.parse.urlencode({
    'encryption': 'none', 'security': 'tls', 'type': 'ws',
    'path': a.path, 'host': a.host, 'sni': a.host,
})
link = f"vless://{a.uuid}@{a.host}:{a.port}?{q}#{urllib.parse.quote(a.name)}"
print(link)
if a.out:
    try:
        import qrcode
        img = qrcode.make(link)
        img.save(a.out)
        print('QR saved to', a.out)
    except ImportError:
        print('qrcode not installed: pip install qrcode[pil], then re-run with --out')

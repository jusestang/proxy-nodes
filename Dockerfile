# Shared proxy-node repo: sing-box VLESS over WebSocket, no TLS of its own.
# The platform terminates TLS (HTTPS) and forwards to this container.
# Works on: Komuta, ZevCloud, orkestr, Cloady (Dockerfile/GitHub path).
# Hostly uses the prebuilt image instead (see README). Eurobase needs
# the Node wrapper in eurobase/ (no Dockerfile builds there).
#
# Base is Debian (glibc), NOT Alpine: sing-box >= 1.13 linux binaries are
# dynamically linked (interpreter /lib64/ld-linux-x86-64.so.2) and cannot
# start on musl/Alpine ("sing-box: not found", exit 127).

FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*
ARG SINGBOX_VERSION=1.14.4
RUN curl -fsSL -o /tmp/sb.tar.gz \
      https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz \
 && tar -xzf /tmp/sb.tar.gz -C /tmp \
 && mv /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box /usr/local/bin/sing-box \
 && mv /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64/libcronet.so /usr/local/lib/libcronet.so \
 && rm -rf /tmp/sb.tar.gz /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

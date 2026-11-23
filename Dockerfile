# Shared proxy-node repo: sing-box VLESS over WebSocket, no TLS of its own.
# The platform terminates TLS (HTTPS) and forwards to this container.
# Works on: Komuta, ZevCloud, orkestr, Cloady (Dockerfile/GitHub path).
# Hostly uses the prebuilt image instead (see README). Eurobase needs
# the Node wrapper in eurobase/ (no Dockerfile builds there).

FROM alpine:3.21
RUN apk add --no-cache ca-certificates curl
ARG SINGBOX_VERSION=1.11.0
RUN curl -fsSL -o /tmp/sb.tar.gz \
      https://github.com/SagerNet/sing-box/releases/download/v${SINGBOX_VERSION}/sing-box-${SINGBOX_VERSION}-linux-amd64.tar.gz \
 && tar -xzf /tmp/sb.tar.gz -C /tmp \
 && mv /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64/sing-box /usr/local/bin/sing-box \
 && rm -rf /tmp/sb.tar.gz /tmp/sing-box-${SINGBOX_VERSION}-linux-amd64
COPY config.json /etc/sing-box/config.json
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

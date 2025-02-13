#

# ===== build stage =====

FROM alpine:latest AS building

# Install required tools (curl and jq for parsing JSON)
RUN apk add --no-cache curl jq

# Automatically get the latest release version of frp
ARG FRP_VER=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | jq -r '.tag_name' | sed "s/v//")

# install frp w/chained one-liner
RUN \
  APK_ARCH="$(apk --print-arch)"; \
  case "$APK_ARCH" in \
    "x86_64") export FRP_ARCH="amd64" ;; \
    "aarch64") export FRP_ARCH="arm64" ;; \
  esac; \
  mkdir -p /frp \
  && curl -L https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_${FRP_ARCH}.tar.gz | tar -xz -C /frp --strip-components=1

# ===== main image =====

FROM alpine:latest

RUN apk add --no-cache curl
COPY --from=building /frp/frpc /usr/bin/frpc

CMD ["/usr/bin/frpc", "-c", "/etc/frp/frpc.toml"]

HEALTHCHECK --start-period=30s --start-interval=2s CMD \
  curl -qfu admin:$(cat /etc/frp/frpc.toml | grep webServer.password | grep -o '"[^"]\+"' | sed 's/"//g') http://127.0.0.1:7400 || exit 1

#

# ===== build stage =====

FROM alpine:latest AS building

# Install required tools (curl and jq for parsing JSON)
RUN apk add --no-cache curl jq

# install frp w/chained one-liner
RUN \
  FRP_VER=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | jq -r '.tag_name' | sed 's/v//'); \
  case "$(apk --print-arch)" in \
    "x86_64") export FRP_ARCH="amd64" ;; \
    "aarch64") export FRP_ARCH="arm64" ;; \
  esac; \
  echo Building FRP ${FRP_VER} ${FRP_ARCH}; \
  mkdir -p /frp \
  && curl -L https://github.com/fatedier/frp/releases/download/v${FRP_VER}/frp_${FRP_VER}_linux_${FRP_ARCH}.tar.gz | tar -xz -C /frp --strip-components=1

# ===== main image =====

FROM alpine:latest

COPY --from=building /frp/frpc /usr/bin/frpc

CMD ["/usr/bin/frpc", "-c", "/etc/frp/frpc.toml"]

HEALTHCHECK --start-period=30s --start-interval=2s CMD \
  [[ $(/usr/bin/frpc status -c /etc/frp/frpc.toml | awk '{print $2}' | grep 'running' | wc -l) -gt 0 ]]

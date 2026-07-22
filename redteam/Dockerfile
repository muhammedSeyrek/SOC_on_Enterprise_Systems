# ============================================================
#  GÖREV: SOC — Red Team toolbox imajı (KİŞİ 1)
#  Herkesin saldırı scriptleri bu imajın üstünde çalışır.
#  radclient (RADIUS) + openvpn-client + python + ağ araçları.
# ============================================================
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      freeradius-utils \
      openvpn \
      python3 python3-requests \
      netcat-openbsd curl iproute2 dnsutils iputils-ping \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /redteam
COPY . /redteam/
RUN find /redteam -name '*.sh' -exec chmod +x {} \; 2>/dev/null || true

# compose entrypoint'i 'sleep infinity' ile override ediyor;
# konteyner ayakta kalır, scriptleri 'docker compose exec' ile çalıştırırsın.

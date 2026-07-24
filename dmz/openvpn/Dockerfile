# KİŞİ 3 — OpenVPN Gateway imajı
FROM debian:12-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      openvpn freeradius-utils iptables iproute2 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY server.conf /etc/openvpn/server.conf
COPY client-connect.sh /etc/openvpn/client-connect.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /etc/openvpn/client-connect.sh /entrypoint.sh
EXPOSE 1194/udp
ENTRYPOINT ["/entrypoint.sh"]

FROM freeradius/freeradius-server:3.2.8

USER root

# Active-response ve ileride eklenecek Wazuh agent için temel araçlar.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        iptables \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Varsayılan modül bağlantılarını kaldır; proje yapılandırmasını image'a bake et.
RUN rm -f \
        /etc/freeradius/mods-enabled/eap \
        /etc/freeradius/mods-enabled/rest \
        /etc/freeradius/mods-enabled/sql \
        /etc/freeradius/sites-enabled/default

COPY mods-enabled/eap /etc/freeradius/mods-enabled/eap
COPY mods-enabled/rest /etc/freeradius/mods-enabled/rest
COPY mods-enabled/sql /etc/freeradius/mods-enabled/sql
COPY mods-enabled/nac_json_log /etc/freeradius/mods-enabled/nac_json_log
COPY sites-enabled/default /etc/freeradius/sites-enabled/default
COPY clients.conf /etc/freeradius/clients.conf

# Wazuh'un okuyacağı ortak volume bu dizine bağlanıyor.
RUN mkdir -p /var/log/radius \
    && touch /var/log/radius/radius.log \
    && chown -R freerad:freerad /var/log/radius \
    && chmod 0750 /var/log/radius \
    && chmod 0640 /var/log/radius/radius.log

EXPOSE 1812/udp 1813/udp

# Base image'ın ENTRYPOINT ve CMD değerleri korunur:
# ENTRYPOINT ["/docker-entrypoint.sh"]
# CMD ["freeradius"]
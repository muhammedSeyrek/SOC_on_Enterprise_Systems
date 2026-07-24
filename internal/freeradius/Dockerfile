FROM freeradius/freeradius-server:3.2.8

USER root

# Active-response ve ileride eklenecek Wazuh agent için temel araçlar.
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        apt-transport-https \
        curl \
        gnupg \
        jq \
        iptables \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Wazuh 4.9 agent paketini resmi depodan kur.
RUN curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH \
    | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import \
    && chmod 0644 /usr/share/keyrings/wazuh.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" \
       > /etc/apt/sources.list.d/wazuh.list \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wazuh-agent=4.9.0-1 \
    && apt-mark hold wazuh-agent \
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

COPY wazuh-agent.conf /opt/wazuh-agent.conf
COPY entrypoint.sh /usr/local/bin/radius-wazuh-entrypoint
RUN chmod 0755 /usr/local/bin/radius-wazuh-entrypoint

ENTRYPOINT ["/usr/local/bin/radius-wazuh-entrypoint"]
CMD ["freeradius"]

EXPOSE 1812/udp 1813/udp


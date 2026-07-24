#!/bin/bash
set -e

WAZUH_MANAGER="${WAZUH_MANAGER:-wazuh-manager}"
WAZUH_AGENT_NAME="${WAZUH_AGENT_NAME:-freeradius}"

cp /opt/wazuh-agent.conf /var/ossec/etc/ossec.conf

if ! grep -q '[^[:space:]]' /var/ossec/etc/client.keys 2>/dev/null; then
    echo "[wazuh] Agent kaydi bekleniyor: ${WAZUH_MANAGER}:1515"

    until /var/ossec/bin/agent-auth \
        -m "$WAZUH_MANAGER" \
        -p 1515 \
        -A "$WAZUH_AGENT_NAME"; do
        echo "[wazuh] Manager hazir degil; 5 saniye sonra tekrar denenecek."
        sleep 5
    done
fi

echo "[wazuh] Agent baslatiliyor."
/var/ossec/bin/wazuh-control start

echo "[radius] FreeRADIUS baslatiliyor."
exec /docker-entrypoint.sh "$@"

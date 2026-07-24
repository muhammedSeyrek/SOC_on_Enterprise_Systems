#!/bin/bash

LOGFILE="/var/ossec/logs/active-responses.log"

INPUT=$(cat)

echo "$INPUT" >> "$LOGFILE"

COMMAND=$(echo "$INPUT" | jq -r '.command')
SRC_IP=$(echo "$INPUT" | jq -r '.parameters.alert.data.src_ip')

if [ -z "$SRC_IP" ] || [ "$SRC_IP" = "null" ]; then
    echo "$(date) quarantine: src_ip not found" >> "$LOGFILE"
    exit 1
fi

case "$COMMAND" in

add)

    iptables -C INPUT -s "$SRC_IP" -j DROP 2>/dev/null || \
    iptables -I INPUT -s "$SRC_IP" -j DROP

    iptables -C OUTPUT -d "$SRC_IP" -j DROP 2>/dev/null || \
    iptables -I OUTPUT -d "$SRC_IP" -j DROP

    echo "$(date) QUARANTINE applied -> $SRC_IP (VLAN99 simulated)" >> "$LOGFILE"
;;

delete)

    iptables -D INPUT -s "$SRC_IP" -j DROP 2>/dev/null
    iptables -D OUTPUT -d "$SRC_IP" -j DROP 2>/dev/null

    echo "$(date) QUARANTINE removed -> $SRC_IP" >> "$LOGFILE"
;;

*)

    echo "$(date) Unknown command: $COMMAND" >> "$LOGFILE"
;;

esac

exit 0
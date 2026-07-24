#!/bin/bash

LOGFILE="/var/ossec/logs/active-responses.log"

INPUT=$(cat)

echo "$INPUT" >> "$LOGFILE"

SRC_IP=$(echo "$INPUT" | jq -r '.parameters.alert.data.src_ip')

if [ -z "$SRC_IP" ] || [ "$SRC_IP" = "null" ]; then
    echo "No source IP found." >> "$LOGFILE"
    exit 1
fi

iptables -C INPUT -s "$SRC_IP" -j DROP 2>/dev/null

if [ $? -ne 0 ]; then
    iptables -I INPUT -s "$SRC_IP" -j DROP
    echo "$(date) Blocked $SRC_IP" >> "$LOGFILE"
fi

exit 0
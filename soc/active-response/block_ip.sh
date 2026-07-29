#!/bin/sh

# Stdin uzerinden gelen JSON verisini oku
INPUT_JSON=$(cat)

# grep ve sed ile IP adresini ayikla (srcip veya src_ip)
IP=$(echo "$INPUT_JSON" | grep -o '"srcip":"[^"]*"' | cut -d'"' -f4)

if [ -z "$IP" ]; then
    IP=$(echo "$INPUT_JSON" | grep -o '"src_ip":"[^"]*"' | cut -d'"' -f4)
fi

LOG_FILE="/var/ossec/logs/active-responses.log"

if [ -n "$IP" ]; then
    iptables -A INPUT -s "$IP" -j DROP
    echo "$(date) - block_ip.sh: Blocked IP $IP" >> "$LOG_FILE" 2>/dev/null
else
    echo "$(date) - block_ip.sh: Could not extract IP from input" >> "$LOG_FILE" 2>/dev/null
fi

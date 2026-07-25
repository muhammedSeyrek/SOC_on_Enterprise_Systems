#!/bin/bash
# ============================================================
#  Wazuh active-response: saldirgan IP'yi iptables ile bloklar.
#  Wazuh execd, karari STDIN'den JSON olarak verir.
#  add  -> DROP kurali ekle
#  delete -> kurali kaldir (timeout_allowed=yes oldugu icin sure
#            dolunca Wazuh ayni scripti delete ile tekrar cagirir)
# ============================================================
LOGFILE="/var/ossec/logs/active-responses.log"
INPUT=$(cat)

# Wazuh komutu: add veya delete
COMMAND=$(echo "$INPUT" | jq -r '.command // empty')

# Saldirgan IP'si: policy-engine loglarindaki data.src_ip alanindan
SRC_IP=$(echo "$INPUT" | jq -r '.parameters.alert.data.src_ip // empty')

if [ -z "$SRC_IP" ] || [ "$SRC_IP" = "null" ]; then
    echo "$(date) [block_ip] source IP bulunamadi, cikiliyor." >> "$LOGFILE"
    exit 1
fi

case "$COMMAND" in
  add)
    # Zaten blokluysa tekrar ekleme (idempotent)
    if iptables -C INPUT -s "$SRC_IP" -j DROP 2>/dev/null; then
        echo "$(date) [block_ip] $SRC_IP zaten blokluydu." >> "$LOGFILE"
    else
        iptables -I INPUT -s "$SRC_IP" -j DROP
        echo "$(date) [block_ip] BLOKLANDI: $SRC_IP" >> "$LOGFILE"
    fi
    ;;
  delete)
    iptables -D INPUT -s "$SRC_IP" -j DROP 2>/dev/null \
      && echo "$(date) [block_ip] blok kaldirildi: $SRC_IP" >> "$LOGFILE"
    ;;
  *)
    echo "$(date) [block_ip] bilinmeyen komut: '$COMMAND'" >> "$LOGFILE"
    exit 1
    ;;
esac
exit 0
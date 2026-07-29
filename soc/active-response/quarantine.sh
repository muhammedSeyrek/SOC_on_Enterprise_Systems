#!/bin/sh

# Stdin uzerinden gelen JSON verisini oku
INPUT_JSON=$(cat)

# Wazuh komutu: add veya delete
COMMAND=$(echo "$INPUT_JSON" | grep -o '"command":"[^"]*"' | cut -d'"' -f4)

# IP adresini ayikla (srcip veya src_ip)
SRC_IP=$(echo "$INPUT_JSON" | grep -o '"srcip":"[^"]*"' | cut -d'"' -f4)
if [ -z "$SRC_IP" ]; then
    SRC_IP=$(echo "$INPUT_JSON" | grep -o '"src_ip":"[^"]*"' | cut -d'"' -f4)
fi

LOG_FILE="/var/ossec/logs/active-responses.log"

if [ -z "$SRC_IP" ] || [ "$SRC_IP" = "null" ]; then
    echo "$(date) [quarantine] Source IP bulunamadi, cikiliyor." >> "$LOG_FILE" 2>/dev/null
    exit 1
fi

QUARANTINE_VLAN_IF="eth0.99"  # VLAN 99 Arayuzu (veya Karantina Subnet'i)
QUARANTINE_NET="192.168.99.0/24"

case "$COMMAND" in
  add)
    # Zaten karantinada mi kontrol et
    if iptables -t mangle -C PREROUTING -s "$SRC_IP" -j MARK --set-mark 99 2>/dev/null; then
        echo "$(date) [quarantine] $SRC_IP zaten VLAN 99 karantinasindaydi." >> "$LOG_FILE" 2>/dev/null
    else
        # Paketleri VLAN 99 mark'i (0x63) ile etiketle ve karantina subnet'ine yonlendir
        iptables -t mangle -A PREROUTING -s "$SRC_IP" -j MARK --set-mark 99
        
        # Alternatif/Destekleyici: Trafigi karantina IP bloğuna DNAT ile yolla
        # iptables -t nat -A PREROUTING -s "$SRC_IP" -j DNAT --to-destination 192.168.99.100
        
        echo "$(date) [quarantine] KARANTINAYA ALINDI (VLAN 99): $SRC_IP" >> "$LOG_FILE" 2>/dev/null
    fi
    ;;

  delete)
    # Karantina etiketini ve kurallarini temizle (while ile tum birikmisleri sil)
    while iptables -t mangle -C PREROUTING -s "$SRC_IP" -j MARK --set-mark 99 2>/dev/null; do
        iptables -t mangle -D PREROUTING -s "$SRC_IP" -j MARK --set-mark 99 2>/dev/null
    done
    echo "$(date) [quarantine] VLAN 99 karantinasi kaldirildi: $SRC_IP" >> "$LOG_FILE" 2>/dev/null
    ;;

  *)
    echo "$(date) [quarantine] Bilinmeyen komut: '$COMMAND'" >> "$LOG_FILE" 2>/dev/null
    exit 1
    ;;
esac

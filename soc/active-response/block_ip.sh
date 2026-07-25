#!/bin/bash
set -u

LOGFILE="/var/ossec/logs/active-responses.log"

log() {
    echo "$(date) [block_ip] $*" >> "$LOGFILE"
}

# Wazuh JSON mesajı tek satırdır. cat kullanma; EOF bekleyerek kilitlenir.
if ! IFS= read -r INPUT; then
    log "STDIN mesaji okunamadi."
    exit 1
fi

COMMAND=$(printf '%s' "$INPUT" | jq -r '.command // empty')
SRC_IP=$(printf '%s' "$INPUT" | jq -r \
    '.parameters.alert.data.src_ip //
     .parameters.alert.data.srcip //
     .parameters.alert.srcip //
     empty')

if [ -z "$SRC_IP" ] || [ "$SRC_IP" = "null" ]; then
    log "source IP bulunamadi."
    exit 1
fi

case "$COMMAND" in
    add)
        # Stateful Active Response için Wazuh'a kontrol anahtarı gönder.
        CHECK_KEYS=$(jq -nc --arg ip "$SRC_IP" \
            '{
                version: 1,
                origin: {
                    name: "block_ip.sh",
                    module: "active-response"
                },
                command: "check_keys",
                parameters: {
                    keys: [$ip]
                }
            }')

        printf '%s\n' "$CHECK_KEYS"

        if ! IFS= read -r RESPONSE; then
            log "check_keys cevabi alinamadi: $SRC_IP"
            exit 1
        fi

        ACTION=$(printf '%s' "$RESPONSE" | jq -r '.command // empty')

        if [ "$ACTION" = "abort" ]; then
            log "tekrarlanan islem iptal edildi: $SRC_IP"
            exit 0
        fi

        if [ "$ACTION" != "continue" ]; then
            log "gecersiz check_keys cevabi: $ACTION"
            exit 1
        fi

        if iptables -C INPUT -s "$SRC_IP" -j DROP 2>/dev/null; then
            log "$SRC_IP zaten blokluydu."
        else
            iptables -I INPUT -s "$SRC_IP" -j DROP
            log "BLOKLANDI: $SRC_IP"
        fi
        ;;

    delete)
        if iptables -C INPUT -s "$SRC_IP" -j DROP 2>/dev/null; then
            iptables -D INPUT -s "$SRC_IP" -j DROP
            log "blok kaldirildi: $SRC_IP"
        else
            log "kaldirilacak blok bulunamadi: $SRC_IP"
        fi
        ;;

    *)
        log "bilinmeyen komut: $COMMAND"
        exit 1
        ;;
esac

exit 0

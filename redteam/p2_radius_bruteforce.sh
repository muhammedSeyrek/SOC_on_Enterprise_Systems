#!/usr/bin/env bash
set -euo pipefail

RADIUS_SERVER="${RADIUS_SERVER:-radius}"
RADIUS_PORT="${RADIUS_PORT:-1812}"
ATTEMPTS="${ATTEMPTS:-6}"
IDENTITY="${IDENTITY:-admin.nac.local}"

if [[ -z "${RADIUS_CLIENT_SECRET:-}" ]]; then
    echo "HATA: RADIUS_CLIENT_SECRET tanımlı değil."
    exit 1
fi

echo "[P2 Red Team] Hedef: ${RADIUS_SERVER}:${RADIUS_PORT}"
echo "[P2 Red Team] Kimlik: ${IDENTITY}"
echo "[P2 Red Team] Deneme sayısı: ${ATTEMPTS}"

for i in $(seq 1 "$ATTEMPTS"); do
    echo "[${i}/${ATTEMPTS}] Hatalı kimlik doğrulama gönderiliyor..."

    printf 'User-Name = "%s"\nUser-Password = "wrong-password-%s"\nNAS-IP-Address = 172.30.0.20\n' \
        "$IDENTITY" "$i" |
        radclient -x "${RADIUS_SERVER}:${RADIUS_PORT}" auth "$RADIUS_CLIENT_SECRET" ||
        true

    sleep 1
done

echo "[P2 Red Team] Tamamlandı."
echo "Kontrol: /var/log/radius/radius.log"

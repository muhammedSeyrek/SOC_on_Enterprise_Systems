#!/bin/bash
# eaptls_expired.sh - Expired Certificate Test via radclient

# Parametreler (Gerektiğinde environment variable ile ezilebilir)
RADIUS_SERVER="${RADIUS_SERVER:-radius}"
RADIUS_PORT="${RADIUS_PORT:-1812}"
RADIUS_SECRET="${RADIUS_SECRET:-testing123}"

echo "=================================================="
echo "[*] Red Team Testi: Expired Certificate / EAP-TLS"
echo "[*] Hedef: ${RADIUS_SERVER}:${RADIUS_PORT}"
echo "=================================================="

# Check if radclient exists
if ! command -v radclient &> /dev/null; then
    echo "[-] HATA: radclient bulunamadı! 'freeradius-utils' paketinin kurulu olduğundan emin olun."
    exit 1
fi

echo "[*] Süresi dolmuş sertifika / yetkisiz kullanıcı için Access-Request paketi gönderiliyor..."

# FreeRADIUS'a gönderilecek RADIUS Access-Request öznitelikleri
# radclient stdin üzerinden anahtar-değer çiftlerini okur
echo "User-Name = 'expired_user@nac.local', NAS-IP-Address = 10.0.0.1, EAP-Type = EAP-TLS" | radclient -x -t 3 -r 1 "$RADIUS_SERVER:$RADIUS_PORT" auth "$RADIUS_SECRET"

RESULT=$?

echo ""
if [ $RESULT -eq 0 ]; then
    echo "[-] UYARI / BAŞARISIZ: Sunucudan Access-Accept döndü!"
    exit 1
else
    echo "[+] BAŞARILI: Istek beklenildiği gibi REDDEDILDI (Access-Reject / Timeout)."
    echo "[+] Logların /logs/radius/radius.log dosyasına ve Wazuh ekranına düştüğünü kontrol edin."
    exit 0
fi
#!/usr/bin/env bash
# ============================================================
#  Bağlantı anında CN'i RADIUS'a sorar (authorization) + loglar.
#  OpenVPN, common_name ve trusted_ip'yi env olarak verir.
#  Revoked/expired certler zaten crl-verify ile TLS'te elenir;
#  buraya sadece geçerli certler ulaşır.
#
#  VPN_RADIUS_ENFORCE=true  -> RADIUS reddederse bağlantıyı kes
#  VPN_RADIUS_ENFORCE=false -> sadece logla, cert kararı geçerli (varsayılan;
#     P2'nin RADIUS'u VPN NAS'ını tanımlayana kadar happy path kırılmasın)
# ============================================================
set -u
CN="${common_name:-unknown}"
SRC="${trusted_ip:-unknown}"
LOG="/var/log/openvpn/vpn-auth.log"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ENFORCE="${VPN_RADIUS_ENFORCE:-false}"

REPLY="$(printf 'User-Name=%s,User-Password=vpn\n' "$CN" \
  | radclient -x radius:1812 auth "${RADIUS_CLIENT_SECRET:-testing123}" 2>&1 || true)"

if echo "$REPLY" | grep -q "Access-Accept"; then
  echo "$TS vpn-auth cn=$CN src=$SRC result=accept" >> "$LOG"
  exit 0
else
  echo "$TS vpn-auth cn=$CN src=$SRC result=reject" >> "$LOG"
  [ "$ENFORCE" = "true" ] && exit 1 || exit 0
fi

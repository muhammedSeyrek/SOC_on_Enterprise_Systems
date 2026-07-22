#!/usr/bin/env bash
# ============================================================
#  GÖREV: SOC — Proje iskeleti oluşturucu (KİŞİ 1)
#  Repo kökünde bir kez çalıştır: tüm klasörleri ve boş stub
#  dosyaları oluşturur. VAR OLAN dosyaların ÜSTÜNE YAZMAZ.
#  Böylece herkesin klasörü hazır, git'te görünür olur.
#    bash scaffold.sh
# ============================================================
set -euo pipefail

# stub <dosya> <sahip> <açıklama>  -> dosya yoksa başlık yorumuyla oluşturur
stub () {
  local f="$1" owner="$2" desc="$3"
  [ -f "$f" ] && { echo "atlandı (var): $f"; return; }
  mkdir -p "$(dirname "$f")"
  case "$f" in
    *.py)  echo "# [$owner] TODO: $desc" > "$f" ;;
    *.sh)  printf '#!/usr/bin/env bash\n# [%s] TODO: %s\n' "$owner" "$desc" > "$f"; chmod +x "$f" ;;
    *.xml) echo "<!-- [$owner] TODO: $desc -->" > "$f" ;;
    *.sql) echo "-- [$owner] TODO: $desc" > "$f" ;;
    *.md)  echo "# TODO ($owner): $desc" > "$f" ;;
    *)     echo "# [$owner] TODO: $desc" > "$f" ;;
  esac
  echo "oluşturuldu: $f"
}

# --- KİŞİ 1: altyapı / PKI / redteam toolbox / docs ---
stub scripts/setup.sh                 P1 "tek komut kurulum: build + pki-init + up"
stub redteam/Dockerfile               P1 "toolbox: radclient + openvpn-client + python"
stub redteam/segmentation_test.sh     P1 "DMZ->ic ag erisim testi (db/policy kapali, radius acik)"
stub docs/architecture.md             P1 "mimari aciklama"
# (scripts/pki/* ve .gitignore zaten hazir — bu script onlara dokunmaz)

# --- KİŞİ 2: freeradius + postgres + redis ---
stub internal/postgres/db-init/01-schema.sql   P2 "radius tablolari + users/profiles/auth_logs"
stub internal/postgres/db-init/02-seed.sql     P2 "admin/employee/guest + VLAN 10/20/30/99"
stub internal/freeradius/Dockerfile            P2 "config BAKED + wazuh-agent + cift-servis entrypoint"
stub internal/freeradius/clients.conf          P2 "OpenVPN NAS (kisitli IP), secret .env'den"
stub internal/freeradius/mods-enabled/eap      P2 "EAP-TLS, CRL kontrolu acik"
stub internal/freeradius/mods-enabled/rest     P2 "POST /authorize -> policy-engine"
stub internal/freeradius/mods-enabled/sql      P2 "postgres accounting/postauth log"
stub internal/freeradius/sites-enabled/default P2 "authorize{eap;rest} + post-auth loglama"
stub redteam/bruteforce_radius.py              P2 "ardisik brute-force + kimlik spoofing"

# --- KİŞİ 3: policy-engine + openvpn + corp-web ---
stub internal/policy-engine/Dockerfile         P3 "FastAPI imaji"
stub internal/policy-engine/requirements.txt   P3 "fastapi, uvicorn, psycopg2, redis, cryptography"
stub internal/policy-engine/app/main.py        P3 "/authorize: kimlik->rol->VLAN, redis sayac, auth_logs"
stub dmz/openvpn/Dockerfile                     P3 "OpenVPN imaji"
stub dmz/openvpn/server.conf                    P3 "udp 1194, crl-verify, kimligi RADIUS'a devret"
stub dmz/corp-web/Dockerfile                    P3 "zafiyetli web imaji"
stub dmz/corp-web/app.py                        P3 "bilincli zafiyetli basit Flask/FastAPI"
stub redteam/vpn_cert_attack.py                 P3 "sahte/revoked cert ile VPN denemesi"

# --- KİŞİ 4: wazuh + active-response ---
stub soc/wazuh/ossec.conf              P4 "localfile + command + active-response tanimlari"
stub soc/wazuh/local_decoder.xml       P4 "radius/policy/openvpn decoder'lari"
stub soc/wazuh/local_rules.xml         P4 "brute-force / cert spoofing / unauthorized access"
stub soc/active-response/block_ip.sh   P4 "iptables DROP (radius agent uzerinde)"
stub soc/active-response/quarantine.sh P4 "VLAN 99'a yonlendir (bonus)"
stub redteam/eaptls_expired.sh         P4 "expired cert ile EAP-TLS handshake"

echo
echo "İskelet hazır."

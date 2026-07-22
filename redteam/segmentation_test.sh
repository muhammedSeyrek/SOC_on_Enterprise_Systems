#!/usr/bin/env bash
# ============================================================
#  GÖREV: SOC — Segmentasyon testi (KİŞİ 1, Red Team)
#  toolbox konteynerinden (dmz_net) çalışır.
#  KANIT: DMZ'den iç ağ servislerine (db, policy-engine) DOĞRUDAN
#         erişilememeli; sadece RADIUS köprüsü açık olmalı.
#  Çalıştırma:  docker compose exec toolbox bash /redteam/segmentation_test.sh
# ============================================================
set -uo pipefail
TIMEOUT="${TIMEOUT:-3}"
fail=0

# Asıl kanıt: iç ağ TCP servisleri KAPALI olmalı
assert_closed () {  # host port label
  if nc -z -w "$TIMEOUT" "$1" "$2" 2>/dev/null; then
    echo "  ✗ BEKLENMEDİK: $3 ($1:$2) ERİŞİLEBİLİR → segmentasyon KIRIK!"
    fail=$((fail+1))
  else
    echo "  ✓ $3 ($1:$2) erişilemez → beklenen (izole)"
  fi
}
# Bilgi amaçlı kontroller (pass/fail'i etkilemez)
info_reach () {  # host port label proto(tcp|udp)
  local flag=""; [ "${4:-tcp}" = "udp" ] && flag="-u"
  if nc -z $flag -w "$TIMEOUT" "$1" "$2" 2>/dev/null; then
    echo "  • $3 ($1:$2) erişilebilir"
  else
    echo "  • $3 ($1:$2) erişilemez"
  fi
}

echo "=== [1] İç ağ servisleri DMZ'den kapalı mı? (segmentasyon kanıtı) ==="
assert_closed db 5432 "PostgreSQL"
assert_closed policy-engine 8000 "Policy Engine"

echo "=== [2] Aynı bölge (DMZ) erişilebilir mi? (kontrol) ==="
info_reach corp-web 8080 "Corp-Web (aynı DMZ)" tcp

echo "=== [3] İzinli köprü açık mı? ==="
info_reach radius 1812 "FreeRADIUS (RADIUS portu)" udp

echo
if [ "$fail" -eq 0 ]; then
  echo "SONUÇ: SEGMENTASYON DOĞRU ✓ (DMZ iç ağa doğrudan erişemiyor)"
  exit 0
else
  echo "SONUÇ: SEGMENTASYON SORUNU ✗ ($fail servis beklenmedik şekilde açık)"
  exit 1
fi

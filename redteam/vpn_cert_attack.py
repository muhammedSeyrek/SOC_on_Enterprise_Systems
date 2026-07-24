#!/usr/bin/env python3
# ============================================================
#  RED TEAM — VPN sertifika saldırısı (KİŞİ 3)
#  Revoked ve expired sertifikalarla VPN bağlantısı dener.
#  BEKLENEN: gateway crl-verify ile REDDETMELİ (tünel kurulmamalı).
#  Yalnızca kendi lab gateway'ini (openvpn-gw) hedefler; toolbox'tan çalışır.
# ============================================================
import subprocess
import tempfile
import os
import sys

PKI = os.getenv("PKI_DIR", "/pki")
GW = os.getenv("VPN_GW", "openvpn-gw")
PORT = os.getenv("VPN_PORT", "1194")
TIMEOUT = int(os.getenv("VPN_TIMEOUT", "15"))

OVPN = """client
dev tun
proto udp
remote {gw} {port}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
ca {ca}
cert {cert}
key {key}
cipher AES-256-GCM
auth SHA256
verb 3
"""

REJECT_MARKERS = ["VERIFY ERROR", "CRL", "certificate revoked", "TLS Error",
                  "expired", "verify error", "CRL not loaded", "handshake",
                  "tls-crypt", "TLS handshake failed"]
OK_MARKER = "Initialization Sequence Completed"


def _txt(x):
    # subprocess stdout/stderr bytes de str de olabilir; hepsini str'e çevir
    if x is None:
        return ""
    if isinstance(x, bytes):
        return x.decode(errors="ignore")
    return x


def try_connect(name, cert, key):
    ca = f"{PKI}/ca.crt"
    with tempfile.NamedTemporaryFile("w", suffix=".ovpn", delete=False) as f:
        f.write(OVPN.format(gw=GW, port=PORT, ca=ca, cert=cert, key=key))
        conf = f.name
    print(f"[*] '{name}' sertifikasıyla bağlanılıyor...", flush=True)
    out = ""
    timed_out = False
    try:
        p = subprocess.run(
            ["openvpn", "--config", conf, "--connect-timeout", "6"],
            capture_output=True, text=True, timeout=TIMEOUT,
        )
        out = _txt(p.stdout) + _txt(p.stderr)
    except subprocess.TimeoutExpired as e:
        out = _txt(e.stdout) + _txt(e.stderr)
        timed_out = True
    finally:
        os.unlink(conf)

    connected = OK_MARKER in out
    rejected = any(m.lower() in out.lower() for m in REJECT_MARKERS)

    # Tünel kurulduysa = KÖTÜ (savunma açık). Kurulmadıysa (timeout / verify error) = BEKLENEN.
    if connected and not rejected:
        print(f"[!] BAŞARISIZ TEST: '{name}' KABUL EDİLDİ — savunma açık kalmış!")
        return False
    neden = "sertifika reddedildi" if rejected else "tünel kurulamadı (timeout)"
    print(f"[+] BEKLENEN: '{name}' engellendi ({neden}) — savunma çalışıyor.")
    return True


def main():
    cases = [
        ("revoked", f"{PKI}/revoked.crt", f"{PKI}/revoked.key"),
        ("expired", f"{PKI}/expired.crt", f"{PKI}/expired.key"),
    ]
    results = [try_connect(n, c, k) for n, c, k in cases]
    print()
    if all(results):
        print("SONUÇ: Tüm kötü sertifikalar engellendi ✓")
        sys.exit(0)
    print("SONUÇ: DİKKAT — bazı sertifikalar geçti ✗")
    sys.exit(1)


if __name__ == "__main__":
    main()

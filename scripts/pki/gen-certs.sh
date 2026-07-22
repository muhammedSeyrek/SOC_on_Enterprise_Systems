#!/usr/bin/env bash
# ============================================================
#  GÖREV: SOC — PKI üretici (KİŞİ 1)
#  Tüm sertifikaları openssl ile üretir ve $PKI_DIR altına yazar.
#  Idempotent: ca.crt zaten varsa hiçbir şey yapmaz (compose her
#  restart'ta yeniden üretmesin diye).
# ============================================================
set -euo pipefail

PKI_DIR="${PKI_DIR:-/pki}"          # compose'da pki volume buraya mount
DOMAIN="${DOMAIN:-nac.local}"
DH_BITS="${DH_BITS:-2048}"          # test için 1024, teslimde 2048
DAYS="${DAYS:-825}"

if [ -f "$PKI_DIR/ca.crt" ]; then
  echo "[pki] ca.crt zaten var — üretim atlandı."
  exit 0
fi

WORK="$(mktemp -d)"
cd "$WORK"

# --- CA veritabanı iskeleti ---
mkdir -p newcerts
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

# --- openssl config ---
cat > openssl.cnf << 'CNF'
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = .
database          = $dir/index.txt
new_certs_dir     = $dir/newcerts
serial            = $dir/serial
crlnumber         = $dir/crlnumber
certificate       = $dir/ca.crt
private_key       = $dir/ca.key
default_md        = sha256
policy            = policy_any
email_in_dn       = no
default_crl_days  = 3650
unique_subject    = no

[ policy_any ]
commonName        = supplied
organizationName  = optional
organizationalUnitName = optional

[ req ]
default_md         = sha256
distinguished_name = dn
prompt             = no

[ dn ]
CN = placeholder

[ v3_ca ]
basicConstraints       = critical,CA:TRUE
keyUsage               = critical,keyCertSign,cRLSign
subjectKeyIdentifier   = hash

[ server_ext ]
basicConstraints       = CA:FALSE
keyUsage               = critical,digitalSignature,keyEncipherment
extendedKeyUsage       = serverAuth
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer

[ client_ext ]
basicConstraints       = CA:FALSE
keyUsage               = critical,digitalSignature
extendedKeyUsage       = clientAuth
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer
CNF

echo "[pki] CA üretiliyor..."
openssl genrsa -out ca.key 4096 2>/dev/null
openssl req -x509 -new -key ca.key -sha256 -days 3650 \
  -subj "/CN=NAC Lab Root CA/O=Grup3" \
  -extensions v3_ca -config openssl.cnf -out ca.crt 2>/dev/null

# --- imzalama yardımcı fonksiyonu ---
# sign <isim> <CN> <ext-section> [ekstra 'openssl ca' argümanları...]
sign () {
  local name="$1" cn="$2" ext="$3"; shift 3
  openssl genrsa -out "$name.key" 2048 2>/dev/null
  openssl req -new -key "$name.key" -subj "/CN=$cn/O=Grup3" \
    -config openssl.cnf -out "$name.csr" 2>/dev/null
  openssl ca -batch -config openssl.cnf -extensions "$ext" \
    -days "$DAYS" "$@" -in "$name.csr" -out "$name.crt" 2>/dev/null
}

echo "[pki] server sertifikası (serverAuth)..."
sign server "server.$DOMAIN" server_ext

echo "[pki] rol sertifikaları (clientAuth, CN=<rol>.$DOMAIN)..."
for role in admin employee guest; do
  sign "$role" "$role.$DOMAIN" client_ext
done

echo "[pki] revoked sertifikası + CRL..."
sign revoked "revoked.$DOMAIN" client_ext
openssl ca -batch -config openssl.cnf -revoke revoked.crt 2>/dev/null
openssl ca -batch -config openssl.cnf -gencrl -out crl.pem 2>/dev/null

echo "[pki] expired sertifikası (geçmiş tarihli)..."
# startdate/enddate geçmişte -> anında süresi dolmuş görünür
sign expired "expired.$DOMAIN" client_ext \
  -startdate 20200101000000Z -enddate 20200201000000Z

echo "[pki] dhparam ($DH_BITS bit) — biraz sürebilir..."
openssl dhparam -out dh.pem "$DH_BITS" 2>/dev/null

# --- çıktıyı PKI_DIR'e kopyala ---
mkdir -p "$PKI_DIR"
cp ca.crt ca.key dh.pem crl.pem "$PKI_DIR/"
for f in server admin employee guest expired revoked; do
  cp "$f.crt" "$f.key" "$PKI_DIR/"
done
chmod 600 "$PKI_DIR"/*.key
echo "[pki] TAMAM. Üretilenler:"
ls -1 "$PKI_DIR"

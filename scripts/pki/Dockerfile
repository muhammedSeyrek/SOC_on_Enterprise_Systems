# ============================================================
#  GÖREV: SOC — PKI üretici imajı (KİŞİ 1)
#  docker-compose'daki `pki-init` servisi bunu bir kez çalıştırır,
#  tüm sertifikaları /pki volume'una yazar ve çıkar.
# ============================================================
FROM alpine:3.20

RUN apk add --no-cache openssl bash

WORKDIR /pki-build
COPY gen-certs.sh /usr/local/bin/gen-certs.sh
RUN chmod +x /usr/local/bin/gen-certs.sh

# Sertifikalar bu dizine yazılır (compose'da `pki` volume buraya mount edilir)
ENV PKI_DIR=/pki
# Teslimde 2048 kalsın; hızlı test için compose'da DH_BITS=1024 verebilirsin.
ENV DH_BITS=2048

ENTRYPOINT ["/usr/local/bin/gen-certs.sh"]
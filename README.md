# SOC on Enterprise Systems — Segmente NAC Altyapısı

Grup 3 · Siber Vatan projesi.

Docker Compose ile kurulan, segmente edilmiş bir Ağ Erişim Kontrol (NAC) laboratuvarı. İki bağımsız giriş yöntemi destekler: uzak kullanıcılar için OpenVPN, yerel kullanıcılar için EAP-TLS. Kullanıcı bağlandığında kimliği doğrulanır, rolüne göre VLAN/erişim profiline atanır. Saldırılar Wazuh (SIEM) ile tespit edilip iptables/karantina ile otomatik engellenir.

Teknolojiler: OpenVPN, FreeRADIUS (EAP-TLS), PostgreSQL, Redis, FastAPI, Wazuh.

## Kurulum (ilk kez)

```bash
git clone https://github.com/muhammedSeyrek/SOC_on_Enterprise_Systems.git
cd SOC_on_Enterprise_Systems

cp env.example .env      # secret degerlerini duzenle
bash scripts/setup.sh    # build + sertifika uretimi + tum servisleri baslat
```

`setup.sh` sırasıyla: imajları derler, `pki-init` ile sertifikaları üretir, servisleri ayağa kaldırır.

Windows PowerShell kullanıyorsan `cp env.example .env` yerine `Copy-Item env.example .env`, `bash scripts/setup.sh` yerine aşağıdaki manuel adımları kullan.

## Manuel çalıştırma

Kurulum scriptini kullanmadan adım adım:

```bash
docker compose build                  # tum imajlari derle
docker compose run --rm pki-init      # sertifikalari uret (bir kez)
docker compose up -d                  # tum servisleri arka planda baslat
```

Tek bir servisi derlemek veya başlatmak:

```bash
docker compose build pki-init
docker compose up -d db redis
```

## Günlük kullanım

```bash
docker compose up -d                  # baslat (arka planda)
docker compose ps                     # calisan servisleri listele
docker compose logs -f radius         # bir servisin loglarini izle
docker compose restart policy-engine  # bir servisi yeniden baslat
docker compose stop                   # durdur (container'lar korunur)
docker compose down                   # durdur ve container/ag'lari sil
```

Bir konteynerin içine girmek:

```bash
docker compose exec radius bash
docker compose exec toolbox bash
```

## Sıfırlama

Veriler ve sertifikalar volume'larda tutulur. Tamamen sıfırdan başlamak için:

```bash
docker compose down -v                # container + ag + volume'lari sil
docker compose build --no-cache
docker compose run --rm pki-init
docker compose up -d
```

Yalnızca sertifikaları yeniden üretmek için:

```bash
docker volume rm nac-soc-lab_pki
docker compose run --rm pki-init
```

`gen-certs.sh` idempotenttir: `ca.crt` mevcutsa hiçbir şey üretmez. Bu yüzden yeniden üretim öncesi volume silinmelidir.

## Doğrulama

Sertifikaların doğruluğu:

```bash
docker run --rm -v nac-soc-lab_pki:/pki alpine:3.20 sh -c "\
  apk add -q openssl; \
  openssl x509 -in /pki/admin.crt -noout -subject -ext extendedKeyUsage; \
  openssl verify -crl_check -CAfile /pki/ca-crl.pem /pki/revoked.crt; \
  openssl verify -crl_check -CAfile /pki/ca-crl.pem /pki/admin.crt"
```

Beklenen: `admin.crt` icin CN=admin.nac.local ve TLS Web Client Authentication, `revoked.crt` icin certificate revoked, `admin.crt` dogrulamasi icin OK.

Ağ segmentasyonu (tüm servisler ayaktayken):

```bash
docker compose exec toolbox bash /redteam/segmentation_test.sh
```

Beklenen: `db:5432` ve `policy-engine:8000` erisilemez, `radius:1812` erisilebilir.

## Ağ planı

| Ağ | Subnet | Erişim |
|----|--------|--------|
| dmz_net | 172.30.0.0/24 | dışa açık |
| internal_net | 172.31.0.0/24 | izole, dış çıkış yok |

| Servis | IP | Not |
|--------|----|-----|
| openvpn | 172.30.0.10 | NAS — clients.conf'ta tanımlı |
| toolbox | 172.30.0.20 | Red Team kaynağı — clients.conf'ta tanımlı |

| Port | Servis | Erişim |
|------|--------|--------|
| 1194/udp | OpenVPN | dışa açık |
| 8080 | corp-web | dışa açık (DMZ) |
| 1812-1813/udp | FreeRADIUS | DMZ ile iç ağ arası tek köprü |
| 5432 | PostgreSQL | yalnızca iç ağ |
| 8000 | Policy Engine | yalnızca iç ağ |

## Klasör yapısı

```
scripts/pki/            CA ve sertifika uretimi (gen-certs.sh)   [P1]
scripts/setup.sh        tek komut kurulum                        [P1]
dmz/openvpn/            VPN gateway                              [P3]
dmz/corp-web/           zafiyetli web servisi                    [P3]
internal/postgres/      sema ve seed (VLAN profilleri)           [P2]
internal/freeradius/    EAP-TLS, rest, sql, wazuh-agent          [P2]
internal/policy-engine/ FastAPI karar motoru                     [P3]
soc/wazuh/              decoder, kurallar, ossec.conf            [P4]
soc/active-response/    iptables blok ve karantina               [P4]
redteam/                saldiri senaryolari (toolbox)            [herkes]
docs/                   mimari, test ve durum raporlari          [P1]
```

## Ekip

| Kişi | Alan |
|------|------|
| P1 | Çekirdek altyapı, PKI, entegrasyon |
| P2 | FreeRADIUS, PostgreSQL, Redis |
| P3 | Policy Engine, OpenVPN, corp-web |
| P4 | Wazuh SOC, active-response |

## Notlar

- Secret'lar `.env` içindedir ve repoya işlenmez (`.gitignore`).
- Sertifikalar ve private key'ler repoya girmez; `pki` volume'unda runtime'da üretilir.
- FreeRADIUS `check_crl = yes` için `ca-crl.pem` (ca.crt + crl.pem birleşimi) kullanılır.
- `server.key` izni 0640, diğer private key'ler 0600'dür.
- VLAN tablosu üç yerde birebir aynı olmalıdır (DB seed, policy-engine, freeradius): admin 10, employee 20, guest 30, quarantine 99.
- Mimari: `docs/architecture.md`. Test kanıtları: `docs/P1-test-raporu.md`. Durum: `docs/P1-durum-raporu.md`.
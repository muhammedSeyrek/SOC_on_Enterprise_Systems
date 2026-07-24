# ============================================================
#  Karar mantığı: kimlik (CN) -> rol -> VLAN
#  PKI'da sertifika CN'i "<rol>.nac.local" formatında (KİŞİ 1).
#  admin.nac.local -> admin ; revoked.nac.local / expired.nac.local -> reddet
# ============================================================

# Bu tablo 3 YERDE AYNI olmalı: policy-engine (burası) + freeradius + DB seed (P2)
VLAN_MAP = {
    "admin": 10,
    "employee": 20,
    "guest": 30,
    "quarantine": 99,
}
VALID_ROLES = {"admin", "employee", "guest"}


def role_from_cn(cn: str):
    """'admin.nac.local' -> 'admin'. Boşsa None."""
    if not cn:
        return None
    return cn.split(".")[0].strip().lower()


def decide(cn: str):
    """(result, role, vlan, reason) döndürür."""
    role = role_from_cn(cn)
    if role in VALID_ROLES:
        return "accept", role, VLAN_MAP[role], "ok"
    # revoked / expired / bilinmeyen CN -> reddet
    return "reject", role, None, "gecersiz_veya_iptal_kimlik"

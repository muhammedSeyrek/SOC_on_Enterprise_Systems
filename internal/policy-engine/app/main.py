# ============================================================
#  NAC Policy Engine — projenin karar merkezi (KİŞİ 3)
#  FreeRADIUS (rlm_rest) her girişte /authorize'ı çağırır.
#  Endpoint'ler: /health, /authorize, /accounting, /logs
#
#  rlm_rest SÖZLEŞMESİ (P2 ile ortak):
#    İstek  (POST /authorize body):
#       {"cn":"admin.nac.local","user":"admin","method":"eap-tls","src_ip":"10.10.0.5"}
#    Yanıt (FreeRADIUS'un anlayacağı attribute JSON'u):
#       accept -> reply:Tunnel-* (VLAN)
#       reject -> control:Auth-Type := Reject
# ============================================================
import os
import json
import logging
import datetime

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from . import policy, db, redis_client

FAIL_THRESHOLD = int(os.getenv("FAIL_THRESHOLD", "5"))
# BONUS: eşik aşılınca reddetmek yerine quarantine VLAN'a al (varsayılan kapalı)
QUARANTINE = os.getenv("QUARANTINE_ON_THRESHOLD", "false").lower() == "true"

LOG_DIR = "/var/log/policy-engine"
os.makedirs(LOG_DIR, exist_ok=True)

# JSON-lines logger (Wazuh decoder'ı bunu okuyacak - KİŞİ 4)
_jsonl = logging.getLogger("policy_jsonl")
_jsonl.setLevel(logging.INFO)
_fh = logging.FileHandler(f"{LOG_DIR}/policy.log")
_fh.setFormatter(logging.Formatter("%(message)s"))
_jsonl.addHandler(_fh)
_sh = logging.StreamHandler()  # docker logs'a da düşsün
_sh.setFormatter(logging.Formatter("%(message)s"))
_jsonl.addHandler(_sh)


def jlog(**kw):
    kw["ts"] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    _jsonl.info(json.dumps(kw, ensure_ascii=False))


app = FastAPI(title="NAC Policy Engine")


@app.on_event("startup")
def _startup():
    try:
        db.init_db()
        jlog(event="startup", status="db_ready")
    except Exception as e:
        jlog(event="startup", status="db_error", error=str(e))


@app.get("/health")
def health():
    return {"status": "ok"}


def _accept_body(role, vlan, msg):
    return {
        "reply:Tunnel-Type": {"op": ":=", "value": ["VLAN"]},
        "reply:Tunnel-Medium-Type": {"op": ":=", "value": ["IEEE-802"]},
        "reply:Tunnel-Private-Group-Id": {"op": ":=", "value": [str(vlan)]},
        "reply:Reply-Message": {"op": ":=", "value": [msg]},
    }


def _reject_body(msg):
    return {
        "control:Auth-Type": {"op": ":=", "value": ["Reject"]},
        "reply:Reply-Message": {"op": ":=", "value": [msg]},
    }


@app.post("/authorize")
async def authorize(request: Request):
    try:
        data = await request.json()
    except Exception:
        data = {}

    cn = (data.get("cn") or data.get("user") or "").strip()
    method = (data.get("method") or "unknown").strip()
    src_ip = (data.get("src_ip") or "unknown").strip()

    result, role, vlan, reason = policy.decide(cn)

    if result == "accept":
        redis_client.reset_fail(src_ip)
        db.insert_log(identity=cn, role=role, method=method, source_ip=src_ip,
                      result="accept", reason=reason, vlan=vlan, fail_count=0)
        jlog(event="auth_decision", identity=cn, role=role, method=method,
             src_ip=src_ip, result="accept", vlan=vlan, reason=reason, fail_count=0)
        return JSONResponse(_accept_body(role, vlan, f"{role} -> VLAN{vlan}"))

    # --- reject yolu ---
    fails = redis_client.incr_fail(src_ip)
    db.insert_log(identity=cn, role=role, method=method, source_ip=src_ip,
                  result="reject", reason=reason, vlan=None, fail_count=fails)
    jlog(event="auth_decision", identity=cn, role=role, method=method,
         src_ip=src_ip, result="reject", reason=reason, fail_count=fails)

    if fails >= FAIL_THRESHOLD:
        # Wazuh brute-force kuralı BU satırı yakalar -> active-response (KİŞİ 4)
        jlog(event="rate_limit_exceeded", src_ip=src_ip, identity=cn, method=method,
             fail_count=fails, threshold=FAIL_THRESHOLD, severity="critical")
        if QUARANTINE:
            qvlan = policy.VLAN_MAP["quarantine"]
            jlog(event="quarantine", src_ip=src_ip, identity=cn, vlan=qvlan)
            return JSONResponse(_accept_body("quarantine", qvlan, "quarantine"))

    return JSONResponse(_reject_body(f"reddedildi: {reason}"))


@app.post("/accounting")
async def accounting(request: Request):
    try:
        data = await request.json()
    except Exception:
        data = {}
    jlog(event="accounting", **{k: data.get(k) for k in ("cn", "user", "method", "src_ip", "status")})
    return {"status": "logged"}


@app.get("/logs")
def logs(limit: int = 50):
    try:
        return {"logs": db.recent_logs(limit)}
    except Exception as e:
        return {"logs": [], "error": str(e)}

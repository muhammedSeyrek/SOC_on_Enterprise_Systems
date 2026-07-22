# ============================================================
#  PostgreSQL: auth kararlarını auth_logs tablosuna yazar.
#  auth_logs tablosunu IF NOT EXISTS ile kendi kurar -> P2'nin şeması
#  gecikirse bile policy-engine çalışır. P2 aynı tabloyu (IF NOT EXISTS)
#  tanımlarsa çakışma olmaz.
# ============================================================
import os
import time
import psycopg2

_conn = None


def _connect():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "db"),
        port=os.getenv("DB_PORT", "5432"),
        dbname=os.getenv("DB_NAME", "radius"),
        user=os.getenv("DB_USER", "radius"),
        password=os.getenv("DB_PASSWORD", ""),
    )


def get_conn():
    global _conn
    if _conn is None or _conn.closed:
        _conn = _connect()
        _conn.autocommit = True
    return _conn


DDL = """
CREATE TABLE IF NOT EXISTS auth_logs (
    id          bigserial PRIMARY KEY,
    ts          timestamptz NOT NULL DEFAULT now(),
    identity    text,
    role        text,
    method      text,
    source_ip   text,
    result      text,
    reason      text,
    vlan        integer,
    fail_count  integer
);
"""


def init_db(retries: int = 15):
    last = None
    for _ in range(retries):
        try:
            with get_conn().cursor() as cur:
                cur.execute(DDL)
            return
        except Exception as e:
            last = e
            global _conn
            _conn = None
            time.sleep(2)
    raise last


def insert_log(**kw):
    try:
        with get_conn().cursor() as cur:
            cur.execute(
                """INSERT INTO auth_logs
                   (identity, role, method, source_ip, result, reason, vlan, fail_count)
                   VALUES (%(identity)s,%(role)s,%(method)s,%(source_ip)s,
                           %(result)s,%(reason)s,%(vlan)s,%(fail_count)s)""",
                kw,
            )
    except Exception:
        # DB düşse bile auth kararını bloklama (jsonl log yine yazılır)
        global _conn
        _conn = None


def recent_logs(limit: int = 50):
    with get_conn().cursor() as cur:
        cur.execute(
            "SELECT ts, identity, role, method, source_ip, result, reason, vlan, fail_count "
            "FROM auth_logs ORDER BY ts DESC LIMIT %s",
            (limit,),
        )
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, [str(v) for v in row])) for row in cur.fetchall()]

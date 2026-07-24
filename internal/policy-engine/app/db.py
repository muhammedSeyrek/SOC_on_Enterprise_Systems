# ============================================================
#  PostgreSQL: auth kararlarını auth_logs tablosuna yazar.
#  ŞEMA P2 (01-schema.sql) ile BİREBİR aynı olmalı:
#    identity, role, method, source_ip, result, reason,
#    vlan_assigned, fail_count
#  db.py'nin kendi CREATE TABLE'ı da bu şemayla aynıdır (P2 gecikirse
#  policy-engine yine çalışır; P2 IF NOT EXISTS ile tanımladığı için çakışmaz).
# ============================================================
import os
import time
import logging

import psycopg2

log = logging.getLogger("policy_db")
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


# P2'nin şemasıyla AYNI: source_ip VARCHAR (INET değil), identity NOT NULL değil
DDL = """
CREATE TABLE IF NOT EXISTS auth_logs (
    id            bigserial PRIMARY KEY,
    ts            timestamptz NOT NULL DEFAULT now(),
    identity      text,
    role          varchar(32),
    method        text,
    source_ip     varchar(45),
    result        text,
    reason        text,
    vlan_assigned integer,
    fail_count    integer
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
    """auth_logs'a bir karar yazar. Hata olursa artık SESSİZ DEĞİL — loglar."""
    try:
        with get_conn().cursor() as cur:
            cur.execute(
                """INSERT INTO auth_logs
                   (identity, role, method, source_ip, result, reason,
                    vlan_assigned, fail_count)
                   VALUES (%(identity)s,%(role)s,%(method)s,%(source_ip)s,
                           %(result)s,%(reason)s,%(vlan_assigned)s,%(fail_count)s)""",
                kw,
            )
    except Exception as e:
        # Hatayı YUTMA, logla — auth kararını yine bloklama ama görünür olsun
        log.error("auth_logs INSERT basarisiz: %s | veri=%s", e, kw)
        global _conn
        _conn = None


def recent_logs(limit: int = 50):
    with get_conn().cursor() as cur:
        cur.execute(
            "SELECT ts, identity, role, method, source_ip, result, reason, "
            "vlan_assigned, fail_count "
            "FROM auth_logs ORDER BY id DESC LIMIT %s",
            (limit,),
        )
        cols = [c[0] for c in cur.description]
        return [dict(zip(cols, [str(v) for v in row])) for row in cur.fetchall()]

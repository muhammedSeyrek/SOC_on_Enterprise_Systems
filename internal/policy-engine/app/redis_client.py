# ============================================================
#  Redis rate-limiting: ardışık başarısız denemeleri sayar.
#  Desen: INCR fail:<anahtar> + ilk artışta EXPIRE(pencere).
# ============================================================
import os
import redis

_r = None
WINDOW = int(os.getenv("FAIL_WINDOW_SECONDS", "60"))


def _client():
    global _r
    if _r is None:
        _r = redis.Redis(
            host=os.getenv("REDIS_HOST", "redis"),
            port=int(os.getenv("REDIS_PORT", "6379")),
            password=os.getenv("REDIS_PASSWORD") or None,
            decode_responses=True,
        )
    return _r


def incr_fail(key: str) -> int:
    try:
        r = _client()
        k = f"fail:{key}"
        n = r.incr(k)
        if n == 1:
            r.expire(k, WINDOW)
        return int(n)
    except Exception:
        return 0


def reset_fail(key: str):
    try:
        _client().delete(f"fail:{key}")
    except Exception:
        pass

# ============================================================
#  DMZ — Zafiyetli "Kurumsal Web Servisi" (KİŞİ 3)
#  !!! BİLİNÇLİ OLARAK ZAFİYETLİ — SADECE LAB İÇİN !!!
#  Gerçek internete ASLA açılmaz. Red Team'in sıçrama noktası.
#
#  Zafiyet: /ping endpoint'inde komut enjeksiyonu (host parametresi
#  doğrudan shell'e geçiyor). Saldırgan buradan iç ağa ulaşmayı dener;
#  segmentasyon sayesinde db/policy-engine'e erişemez -> bu kanıtlanır.
# ============================================================
import subprocess
import datetime
import logging
import os
from flask import Flask, request, jsonify

os.makedirs("/var/log/corp-web", exist_ok=True)
logging.basicConfig(
    filename="/var/log/corp-web/access.log",
    level=logging.INFO,
    format="%(message)s",
)
app = Flask(__name__)


def jlog(**kw):
    kw["ts"] = datetime.datetime.utcnow().isoformat() + "Z"
    logging.info(kw)


@app.route("/")
def index():
    return "Kurumsal Web Servisi (LAB - zafiyetli)\n"


@app.route("/ping")
def ping():
    host = request.args.get("host", "127.0.0.1")
    jlog(event="ping", host=host, src=request.remote_addr)
    # !!! ZAFİYET: shell=True + doğrudan interpolasyon (komut enjeksiyonu) !!!
    out = subprocess.run(
        f"ping -c 1 {host}", shell=True,
        capture_output=True, text=True, timeout=10,
    )
    return jsonify(cmd=f"ping -c 1 {host}", stdout=out.stdout, stderr=out.stderr)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

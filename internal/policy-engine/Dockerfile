# KİŞİ 3 — FastAPI Policy Engine imajı
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
RUN mkdir -p /var/log/policy-engine
EXPOSE 8000
# compose'da POLICY_ENGINE_URL=http://policy-engine:8000/authorize bekleniyor
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

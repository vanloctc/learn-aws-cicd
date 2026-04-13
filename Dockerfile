# ─────────────────────────────────────────────────────────────────────────────
# Dockerfile — Realtime Clock App
# Multi-stage build: builder → runtime (slim)
# Target: AWS ECS (Fargate / EC2 launch type)
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Builder ──────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install only build-time deps
COPY requirements.txt .
RUN pip install --upgrade pip --quiet \
 && pip install --prefix=/install --no-cache-dir -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Non-root user for security (ECS best practice)
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /install /usr/local

# Copy application source
COPY app.py         .
COPY templates/     ./templates/

# Ownership
RUN chown -R appuser:appuser /app

USER appuser

# ── Environment defaults (override via ECS Task Definition) ───────────────
ENV FLASK_ENV=production \
    PORT=8080 \
    WORKERS=2 \
    TIMEOUT=60 \
    APP_VERSION=1.0.0

EXPOSE 8080

# Health check — used by ECS to determine container health
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

# Gunicorn as entrypoint
CMD ["sh", "-c", \
     "gunicorn --bind 0.0.0.0:${PORT} --workers ${WORKERS} --timeout ${TIMEOUT} --access-logfile - --error-logfile - app:app"]

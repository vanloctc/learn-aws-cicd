#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/start_server.sh
# CodeDeploy hook: ApplicationStart
# Launch Gunicorn as a background daemon.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/realtime-clock"
VENV="$APP_DIR/.venv"
LOG_DIR="/var/log/realtime-clock"
LOG_FILE="$LOG_DIR/deploy.log"
ACCESS_LOG="$LOG_DIR/access.log"
ERROR_LOG="$LOG_DIR/error.log"
PID_FILE="$APP_DIR/gunicorn.pid"

# Runtime config (override via /etc/realtime-clock.env)
PORT="${PORT:-8080}"
WORKERS="${WORKERS:-2}"
TIMEOUT="${TIMEOUT:-60}"
DEPLOY_ENV="${DEPLOY_ENV:-production}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] START | $*" | tee -a "$LOG_FILE"; }

log "=== ApplicationStart hook ==="
log "DEPLOY_ENV : $DEPLOY_ENV"
log "PORT       : $PORT"
log "WORKERS    : $WORKERS"

# Load optional env overrides
[ -f /etc/realtime-clock.env ] && source /etc/realtime-clock.env

cd "$APP_DIR"
source "$VENV/bin/activate"

# Start Gunicorn
"$VENV/bin/gunicorn" \
    --bind "0.0.0.0:$PORT" \
    --workers "$WORKERS" \
    --timeout "$TIMEOUT" \
    --pid "$PID_FILE" \
    --access-logfile "$ACCESS_LOG" \
    --error-logfile "$ERROR_LOG" \
    --log-level info \
    --daemon \
    app:app

log "Gunicorn started with PID $(cat $PID_FILE)"
log "ApplicationStart complete"
exit 0

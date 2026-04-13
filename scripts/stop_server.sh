#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/stop_server.sh
# CodeDeploy hook: ApplicationStop
# Gracefully stop the running Gunicorn process (if any).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/realtime-clock"
PID_FILE="$APP_DIR/gunicorn.pid"
LOG_FILE="/var/log/realtime-clock/deploy.log"

mkdir -p "$(dirname $LOG_FILE)"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] STOP  | $*" | tee -a "$LOG_FILE"; }

log "=== ApplicationStop hook ==="

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        log "Sending SIGTERM to PID $PID"
        kill -TERM "$PID"
        # Wait up to 15 s for graceful shutdown
        for i in $(seq 1 15); do
            sleep 1
            kill -0 "$PID" 2>/dev/null || { log "Process $PID stopped after ${i}s"; break; }
        done
        # Force kill if still running
        if kill -0 "$PID" 2>/dev/null; then
            log "Force-killing PID $PID"
            kill -9 "$PID" || true
        fi
    else
        log "PID $PID not running – nothing to stop"
    fi
    rm -f "$PID_FILE"
else
    log "No PID file found – assuming app is not running"
fi

# Belt-and-suspenders: kill any stray gunicorn processes for this app
pkill -f "gunicorn.*app:app" 2>/dev/null && log "Killed stray gunicorn processes" || true

log "ApplicationStop complete"
exit 0

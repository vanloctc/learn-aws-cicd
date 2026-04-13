#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/validate_service.sh
# CodeDeploy hook: ValidateService
# Confirm the app is responding to HTTP health checks.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

PORT="${PORT:-8080}"
LOG_FILE="/var/log/realtime-clock/deploy.log"
MAX_RETRIES=10
SLEEP_SEC=3

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] VALID | $*" | tee -a "$LOG_FILE"; }

log "=== ValidateService hook ==="
log "Probing http://localhost:$PORT/health ..."

for i in $(seq 1 $MAX_RETRIES); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/health" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        log "Health check PASSED (HTTP $HTTP_CODE) on attempt $i"
        log "ValidateService complete – deployment successful ✅"
        exit 0
    fi
    log "Attempt $i/$MAX_RETRIES – HTTP $HTTP_CODE – retrying in ${SLEEP_SEC}s ..."
    sleep $SLEEP_SEC
done

log "ERROR: Health check FAILED after $MAX_RETRIES attempts – rolling back"
exit 1

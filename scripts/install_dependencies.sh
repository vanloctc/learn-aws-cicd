#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/install_dependencies.sh
# CodeDeploy hook: AfterInstall
# Install Python packages into the virtual environment.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/realtime-clock"
VENV="$APP_DIR/.venv"
LOG_FILE="/var/log/realtime-clock/deploy.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] DEPS  | $*" | tee -a "$LOG_FILE"; }

log "=== AfterInstall (install_dependencies) hook ==="
log "APP_DIR : $APP_DIR"
log "VENV    : $VENV"

# Activate venv
# shellcheck source=/dev/null
source "$VENV/bin/activate"

# Upgrade pip silently
pip install --upgrade pip --quiet

# Install app dependencies
log "Installing requirements ..."
pip install -r "$APP_DIR/requirements.txt" --quiet
log "Packages installed:"
pip list --format=columns | grep -E "Flask|gunicorn|flask-cors"

deactivate
log "AfterInstall complete"
exit 0

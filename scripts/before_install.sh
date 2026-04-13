#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# scripts/before_install.sh
# CodeDeploy hook: BeforeInstall
# Create directory structure and ensure Python 3.11 is available.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/realtime-clock"
LOG_DIR="/var/log/realtime-clock"
LOG_FILE="$LOG_DIR/deploy.log"

mkdir -p "$APP_DIR" "$LOG_DIR"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] PRE   | $*" | tee -a "$LOG_FILE"; }

log "=== BeforeInstall hook ==="

# ── Ensure Python 3.11 is present ─────────────────────────────────────────
if ! command -v python3.11 &>/dev/null; then
    log "Installing Python 3.11 ..."
    if command -v dnf &>/dev/null; then
        dnf install -y python3.11 python3.11-pip      # Amazon Linux 2023
    elif command -v yum &>/dev/null; then
        amazon-linux-extras install python3.11 -y     # Amazon Linux 2
    elif command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y python3.11 python3.11-venv
    fi
fi
log "Python: $(python3.11 --version)"

# ── Create / clean virtual environment ────────────────────────────────────
VENV="$APP_DIR/.venv"
if [ -d "$VENV" ]; then
    log "Removing old venv at $VENV"
    rm -rf "$VENV"
fi
python3.11 -m venv "$VENV"
log "Created venv: $VENV"

# ── Fix ownership ──────────────────────────────────────────────────────────
chown -R ec2-user:ec2-user "$APP_DIR" "$LOG_DIR"

log "BeforeInstall complete"
exit 0

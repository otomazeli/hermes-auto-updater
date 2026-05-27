#!/bin/bash
# hermes-update-apply — Stage 2: applies update if pending and not paused.
# Part of the hermes-auto-updater skill.
set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
LOG_FILE="$HERMES_HOME/logs/auto-update.log"
PENDING_FILE="$HERMES_HOME/.pending-update"
PAUSE_FILE="$HERMES_HOME/.pause-auto-update"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

NOTIFY_CONF="$HERMES_HOME/.auto-updater/notify.conf"

send_notification() {
    local msg="$1"
    if [ -f "$NOTIFY_CONF" ]; then
        # shellcheck source=/dev/null
        . "$NOTIFY_CONF"
        if [ -n "${NOTIFY_CMD:-}" ]; then
            eval "$NOTIFY_CMD" 2>/dev/null || true
        fi
    fi
}

# --- Gate checks ---

if [ ! -f "$PENDING_FILE" ]; then
    log "No pending update marker. Nothing to do."
    exit 0
fi

if [ -f "$PAUSE_FILE" ]; then
    PAUSE_REASON=$(cat "$PAUSE_FILE" 2>/dev/null || echo "no reason given")
    log "Update paused by user. Reason: $PAUSE_REASON"
    rm -f "$PENDING_FILE"
    send_notification "⏸ Hermes auto-update paused.\nReason: $PAUSE_REASON"
    exit 0
fi

# --- Notify before starting ---

COMMITS=$((git -C "$HERMES_HOME/hermes-agent" log HEAD..origin/main --oneline 2>/dev/null | wc -l) || echo "?")
START_MSG="🔧 Starting Update\nApplying ${COMMITS} commit(s) to Hermes now..."
log "$START_MSG"
send_notification "$START_MSG"

# --- Apply update ---

UPDATE_OUTPUT=$(hermes update -y 2>&1) || {
    ERR="❌ Hermes auto-update FAILED.\nLogs: $LOG_FILE"
    log "ERROR: Update failed."
    send_notification "$ERR"
    rm -f "$PENDING_FILE"
    exit 1
}

NEW_VER=$(hermes --version | head -1)
SUCCESS_MSG="✅ Hermes auto-update complete.\nVersion: $NEW_VER"
log "$SUCCESS_MSG"
log "Update details: $UPDATE_OUTPUT"
send_notification "$SUCCESS_MSG"
rm -f "$PENDING_FILE"

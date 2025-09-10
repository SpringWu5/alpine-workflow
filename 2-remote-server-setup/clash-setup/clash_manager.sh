#!/bin/bash

# --- Clash Process Manager (Final, Corrected Version) ---

CLASH_DIR="/lustre/neutrino/wujiacheng/clash"
LOCK_DIR="$HOME/.clash.lock"   # Using a directory for atomic locking
PID_FILE="$LOCK_DIR/clash.pid" # PID file is inside the lock directory
LOG_FILE="$LOCK_DIR/manager.log"

# --- Logging Function ---
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >>"$LOG_FILE"
}

# --- Cleanup Function ---
# This trap is the guarantee of shutdown.
cleanup() {
  log "Cleanup triggered."
  if [ -f "$PID_FILE" ]; then
    CLASH_PID_TO_KILL=$(cat "$PID_FILE")
    log "Found Clash PID $CLASH_PID_TO_KILL. Terminating..."
    kill "$CLASH_PID_TO_KILL" 2>/dev/null
  fi
  # Remove the lock directory, signaling we are fully down.
  rm -rf "$LOCK_DIR"
  log "Cleanup complete. Manager is shutting down."
}
trap cleanup EXIT SIGINT SIGTERM SIGHUP

# --- Main Execution ---
log "Manager started."

# Start Clash in the background and IMMEDIATELY capture its PID.
cd "$CLASH_DIR"
./clash -d . &
CLASH_PID=$!

# Write the PID to the file. This is our single source of truth for shutdown.
echo "$CLASH_PID" >"$PID_FILE"
log "Clash started with PID $CLASH_PID."

log "Starting to monitor SSH sessions..."
# Loop as long as there are active sshd sessions. pgrep is reliable.
while pgrep -u "$(whoami)" sshd >/dev/null; do
  sleep 15
done

log "No active SSH sessions detected. Triggering shutdown."
# The script now exits, and the 'trap' will automatically run the cleanup function.

#!/bin/bash

# Configuration
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
LOG_FILE="/tmp/obsidian_sync_pc1.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Navigate to Vault
cd "$VAULT_PATH" || { echo "Vault path not found"; exit 1; }

# Function for logging
log() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

log "--- Starting Sync ---"

# 1. Commit Local State (Handle Dirty State)
if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "PC1: Auto-save at $DATE"
    log "Local changes committed."
else
    log "No local changes to commit."
fi

# 2. Pull Remote Main (Fast-forward only to avoid local merge bubbles)
git pull --ff-only origin main >> "$LOG_FILE" 2>&1

# 3. Fetch PC2
git fetch origin pc2-satellite >> "$LOG_FILE" 2>&1

# 4. Merge PC2 into Main
# We attempt the merge. If it fails, git returns non-zero.
if git merge origin/pc2-satellite --no-edit >> "$LOG_FILE" 2>&1; then
    log "Merge successful."
    
    # 5. Push Result
    git push origin main >> "$LOG_FILE" 2>&1
    log "Pushed to origin/main. Sync Complete."
else
    log "CRITICAL: Merge Conflict Detected."
    
    # Send System Notification (Works on Gnome/KDE/XFCE)
    # You may need to set specific DBUS variables if running via Cron
    notify-send "Obsidian Sync Failed" "Merge conflict with PC2. Please resolve manually." -u critical
    
    # Do NOT reset. Leave the repo in conflict state for the user to fix.
    exit 1
fi
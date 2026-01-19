#!/bin/bash

# Configuration
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
LOG_FILE="/tmp/obsidian_sync_pc1.log"
QUEUE_BRANCH="conflict-queue"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# the two lines '||' make an operator with runs the code to the left is the right side fails.
cd "$VAULT_PATH" || exit 1

# $1 is the first parameter sent to log function when it is called.
log() { echo "[$DATE] $1" >> "$LOG_FILE"; }

log "--- Starting Master Sync ---"

# 1. Commit Local
if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "SW: Save at $DATE"
fi

# 2. Pull Remote Main
git pull --ff-only origin main >> "$LOG_FILE" 2>&1

# 3. Fetch PC2
git fetch origin pc2-satellite >> "$LOG_FILE" 2>&1

# 4. TEST MERGE (Dry Run)
# We try to merge in memory without committing
if git merge --no-commit --no-ff origin/pc2-satellite > /dev/null 2>&1; then
    # --- SUCCESS CASE ---
    log "Merge clean. Committing..."
    git commit -m "Merged PC2 into Main" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
    log "Sync Complete (Clean)."
else
    # --- CONFLICT CASE ---
    log "Conflict detected! Skipping merge."
    
    # Abort the test merge to clean up the workspace
    git merge --abort >> "$LOG_FILE" 2>&1
    
    # Save the conflicting PC2 commit to a separate branch so we don't lose it
    # This force-updates 'conflict-queue' to match PC2's current state
    git branch -f "$QUEUE_BRANCH" origin/pc2-satellite
    git push origin "$QUEUE_BRANCH" --force >> "$LOG_FILE" 2>&1
    
    log "Conflicting changes saved to branch '$QUEUE_BRANCH'."
    
    # Send Notification
    # notify-send "Obsidian Sync" "Conflict skipped. Saved to '$QUEUE_BRANCH'." -u normal
    
    # Push our local Main updates anyway (so PC2 stays updated)
    git push origin main >> "$LOG_FILE" 2>&1
fi
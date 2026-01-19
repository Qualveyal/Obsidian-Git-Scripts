#!/bin/bash

# Configuration
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
LOG_FILE="/tmp/obsidian_sync_pc1.log"
JOURNAL_FILE="Conflict_Journal.md"
DATE=$(date "+%Y-%m-%d %H:%M:%S")
SW_BRANCH="main"
AC_BRANCH="pc2-satellite"

cd "$VAULT_PATH" || exit 1

log() { echo "[$DATE] $1" >> "$LOG_FILE"; }

log "--- Starting Master Sync (Journal Mode) ---"

# 1. Commit Local Changes
if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "PC1: Auto-save at $DATE"
fi

# 2. Pull Remote Main (Fast-forward)
#####
# Discuss how this can fail.
#####
git pull --ff-only origin main >> "$LOG_FILE" 2>&1

# 3. Fetch PC2
git fetch origin "$AC_BRANCH" >> "$LOG_FILE" 2>&1

# 4. DRY RUN: Check for Conflicts
# We attempt a merge in memory (--no-commit) to see if it explodes.
if git merge --no-commit --no-ff origin/"$AC_BRANCH" > /dev/null 2>&1; then
    # --- NO CONFLICTS ---
    log "Merge clean. Committing..."
    git commit -m "Merged PC2 into Main" >> "$LOG_FILE" 2>&1
    git push origin main >> "$LOG_FILE" 2>&1
    log "Sync Complete (Clean)."

else
    # --- CONFLICT DETECTED ---
    log "Conflict detected. Initiating Journaling protocol."
    
    # 1. Identify the conflicting files
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    
    # 2. Get the specific commit hash from PC2 that holds the lost data
    PC2_HASH=$(git rev-parse origin/"$AC_BRANCH")
    
    # 3. Abort the merge to return files to clean PC1 state
    git merge --abort >> "$LOG_FILE" 2>&1
    
    # 4. Write to the Journal
    # We append to the top or bottom. Appending to bottom is safer for scripts.
    echo "" >> "$JOURNAL_FILE"
    echo "## Conflict Detected: $DATE" >> "$JOURNAL_FILE"
    echo "PC1 refused to merge the following files from PC2:" >> "$JOURNAL_FILE"
    for file in $CONFLICT_FILES; do
        echo "- [[$file]]" >> "$JOURNAL_FILE"
    done
    echo "**Data Location:** The lost changes are in Commit \`$PC2_HASH\` on branch \`$AC_BRANCH\`." >> "$JOURNAL_FILE"
    echo "---" >> "$JOURNAL_FILE"
    
    log "Conflict details logged to $JOURNAL_FILE"
    
    # 5. Commit ONLY the Journal (and any other local changes)
    git add "$JOURNAL_FILE"
    git commit -m "PC1: Logged conflict from PC2 ($PC2_HASH)" >> "$LOG_FILE" 2>&1
    
    # 6. Push Main
    # We push the updated Journal so PC2 sees it.
    # We did NOT merge the actual conflicting content, so Main remains authoritative.
    git push origin main >> "$LOG_FILE" 2>&1
    
fi
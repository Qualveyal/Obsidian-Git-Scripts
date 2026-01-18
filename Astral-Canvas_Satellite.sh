#!/bin/bash

# Configuration
VAULT_PATH="/home/user/Documents/ObsidianVault"
LOG_FILE="/tmp/obsidian_sync_pc2.log"
VAULT_CONFLICT_LOG="Conflict_Log.md" # Inside the vault
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Navigate
cd "$VAULT_PATH" || { echo "Vault path not found"; exit 1; }

log() {
    echo "[$DATE] $1" >> "$LOG_FILE"
}

log "--- Starting Satellite Sync ---"

# Ensure branch
git checkout pc2-satellite >> "$LOG_FILE" 2>&1

# 1. Commit Local State
if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "PC2: Auto-save at $DATE"
    log "Local changes committed."
fi

# 2. Push Local to Satellite Branch
git push origin pc2-satellite >> "$LOG_FILE" 2>&1

# 3. Fetch Master
git fetch origin main >> "$LOG_FILE" 2>&1

# 4. PRE-CHECK: Detect potential conflicts
# We use `git merge-tree` to simulate the merge in memory and list conflicting files.
# syntax: git merge-tree <base-tree> <branch1> <branch2>
# But a simpler way for scripting is `git merge --no-commit --no-ff` and checking status, then aborting.
# However, aborting leaves lock files. 

# precise method: use git merge-tree (Git 2.38+) or fallback to trial merge.
# We will use the trial merge method for compatibility.

CONFLICTS_DETECTED=0
CONFLICT_FILES=""
PRE_MERGE_HASH=$(git rev-parse HEAD)

# Attempt a merge *without* auto-resolution to see if it fails
if ! git merge origin/main --no-commit --no-ff > /dev/null 2>&1; then
    CONFLICTS_DETECTED=1
    # Get list of conflicting files (Unmerged paths)
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    
    log "Potential conflict detected in: $CONFLICT_FILES"
    
    # ABORT this test merge to return to clean state
    git merge --abort
fi

# 5. Handle Logging (If conflict was found)
if [ $CONFLICTS_DETECTED -eq 1 ]; then
    echo "## Silent Conflict Resolved - $DATE" >> "$VAULT_CONFLICT_LOG"
    echo "The following files had conflicts and were overwritten by Main (PC1):" >> "$VAULT_CONFLICT_LOG"
    echo "" >> "$VAULT_CONFLICT_LOG"
    
    for file in $CONFLICT_FILES; do
        echo "- [[$file]]" >> "$VAULT_CONFLICT_LOG"
    done
    
    echo "" >> "$VAULT_CONFLICT_LOG"
    echo "**Recover local PC2 version from Commit:** \`$PRE_MERGE_HASH\`" >> "$VAULT_CONFLICT_LOG"
    echo "---" >> "$VAULT_CONFLICT_LOG"
    
    # We must commit this log file BEFORE the merge, or it gets messy.
    git add "$VAULT_CONFLICT_LOG"
    git commit -m "PC2: Logged conflict details"
    
    # Update our recovery hash variable because we just made a new commit
    PRE_MERGE_HASH=$(git rev-parse HEAD)
fi

# 6. The Real Merge (With Authority Strategy)
# Now we do the actual merge that prefers PC1
git merge origin/main -X theirs --no-edit -m "PC2: Sync from Main (Conflicts Resolved Silently)" >> "$LOG_FILE" 2>&1

log "Merged Main into PC2."

# 7. Push Result
git push origin pc2-satellite >> "$LOG_FILE" 2>&1

log "Sync Complete."
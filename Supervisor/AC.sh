#!/bin/bash

# Configuration
VAULT_PATH="/home/user/Documents/ObsidianVault"
RECOVERY_LOG="PC2_Recovery_Log.md" # Owned by PC2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Satellite Sync (PC2) ===${NC}"

cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found!${NC}"; exit 1; }

# Ensure Branch
if [ "$(git rev-parse --abbrev-ref HEAD)" != "pc2-satellite" ]; then
    git switch pc2-satellite
fi

# 1. Commit Local
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Local changes detected. Committing...${NC}"
    git add .
    git commit -m "PC2: Manual Sync $(date "+%Y-%m-%d %H:%M")"
fi

# 2. Push Local (Backup BEFORE overwrite)
echo -e "${BLUE}Pushing local state to GitHub...${NC}"
git push origin pc2-satellite

# Capture current hash for the receipt
SAFE_HASH=$(git rev-parse HEAD)

# 3. Fetch Master
echo -e "${BLUE}Fetching Main...${NC}"
git fetch origin main

# 4. Check for Conflicts (Witness & Log)
CONFLICT_DETECTED=0

if ! git merge --no-commit --no-ff origin/main > /dev/null 2>&1; then
    CONFLICT_DETECTED=1
    echo -e "${RED}⚠️  CONFLICT DETECTED - Files will be overwritten!${NC}"
    
    # Get list of files
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    
    # Abort dry run
    git merge --abort
    
    # --- WRITE RECEIPT LOG ---
    echo -e "${YELLOW}Logging recovery details to $RECOVERY_LOG...${NC}"
    
    echo "" >> "$RECOVERY_LOG"
    echo "## Overwrite Receipt - $(date "+%Y-%m-%d %H:%M")" >> "$RECOVERY_LOG"
    echo "The following local files were overwritten by Main:" >> "$RECOVERY_LOG"
    for file in $CONFLICT_FILES; do
        echo "- [[$file]]" >> "$RECOVERY_LOG"
    done
    echo "**Recovery Hash:** \`$SAFE_HASH\`" >> "$RECOVERY_LOG"
    echo "---" >> "$RECOVERY_LOG"
    
    # We must commit this log file immediately so it survives the merge
    git add "$RECOVERY_LOG"
    git commit -m "PC2: Logged recovery receipt"
    
    echo -e "${RED}Proceeding with overwrite (Authority Strategy)...${NC}"
    sleep 2
fi

# 5. Merge Main (Authority Strategy)
echo -e "${BLUE}Merging Main into PC2...${NC}"
if git merge origin/main -X theirs --no-edit -m "PC2: Sync from Main"; then
    if [ $CONFLICT_DETECTED -eq 1 ]; then
        echo -e "${YELLOW}Merge complete. Local conflicts overwritten.${NC}"
        echo -e "${YELLOW}See $RECOVERY_LOG for details.${NC}"
    else
        echo -e "${GREEN}Merge Successful.${NC}"
    fi
else
    echo -e "${RED}Merge failed. Check status.${NC}"
    exit 1
fi

# 6. Push Result (Sends the Log + The Merge)
echo -e "${BLUE}Pushing result to GitHub...${NC}"
git push origin pc2-satellite

echo -e "${GREEN}✅ Sync Complete.${NC}"
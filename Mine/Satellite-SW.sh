#!/bin/bash

# === CONFIGURATIONS ===
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
DEVICE_BRANCH="sat-1"
# Specific files to auto-resolve in favor of Main (Space separated)
RECOVERY_LOG="${DEVICE_BRANCH}_Recovery_Log.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Satellite Sync - ($DEVICE_BRANCH) ===${NC}"
cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found!${NC}"; exit 1; }

# 0. Ensure we are in the correct Satellite branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$DEVICE_BRANCH" ]; then
    echo -e "${YELLOW}Switching to branch $DEVICE_BRANCH...${NC}"
    git checkout "$DEVICE_BRANCH" || { echo -e "${DEVICE_BRANCH} does not exits"; exit 1; }
fi

# 1. Commit local work
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Committing local changes...${NC}"
    git add .
    git commit -m "$DEVICE_BRANCH: Manual Sync $(date "+%Y-%m-%d %H:%M")"
fi

# 2. Push to Satellite
echo -e "${BLUE}Pushing local state to $DEVICE_BRANCH...${NC}"
# git push origin "$DEVICE_BRANCH"
echo 'git push origin "$DEVICE_BRANCH"'

# 3. Fetch Main
echo -e "${BLUE}Fetching Main...${NC}"
git fetch origin main

# Capture current hash (Safety Net)
SAFE_HASH=$(git rev-parse HEAD)

# 4. Attempt Merge from Main
# We check if Main has updates that conflict with us
CONFLICT_DETECTED=0

if ! git merge --no-commit --no-ff origin/main > /dev/null 2>&1; then
    CONFLICT_DETECTED=1
    echo -e "${RED}CONFLICT DETECTED - Main has authoritative updates!${NC}"
    
    # Get list of conflicting files
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    
    # Abort the dry run
    git merge --abort
    
    # --- WRITE RECEIPT LOG ---
    echo -e "${YELLOW}Logging recovery details to $RECOVERY_LOG...${NC}"
    
    echo "" >> "$RECOVERY_LOG"
    echo "## Overwrite Receipt - $(date "+%Y-%m-%d %H:%M")" >> "$RECOVERY_LOG"
    echo "The following local files were overwritten by Main:" >> "$RECOVERY_LOG"
    for file in $CONFLICT_FILES; do
        echo "- [[$file]]" >> "$RECOVERY_LOG"
    done
    echo "**Recovery Hash**: \`$SAFE_HASH\` in \`$DEVICE_BRANCH\`" >> "$RECOVERY_LOG"
    echo "---" >> "$RECOVERY_LOG"
    
    # Commit the log so it survives the overwrite
    git add "$RECOVERY_LOG"
    git commit -m "$DEVICE_BRANCH: Logged recovery receipt"
    
    echo -e "${RED}Overwriting local conflicts with Main...${NC}"
    sleep 2
fi

# 5. Execute Merge
# If conflict, take Main's version (-X theirs)
if git merge origin/main -X theirs --no-edit -m "Sync from Main"; then
    if [ $CONFLICT_DETECTED -eq 1 ]; then
        echo -e "${YELLOW}Merge complete. Conflicts overwritten. See $RECOVERY_LOG.${NC}"
    else
        echo -e "${GREEN}Merge Clean (or Fast-Forward).${NC}"
    fi
else
    echo -e "${RED}CRITICAL: Merge failed unexpectedly.${NC}"
    exit 1
fi

# 6. Push Final Result to Satellite
echo -e "${BLUE}Pushing final state to $DEVICE_BRANCH...${NC}"
git push origin "$DEVICE_BRANCH"

echo -e "${GREEN}✅ Daily Sync Complete.${NC}"












#!/bin/bash

# Configurations
SAT_1="sat-1"; SAT_2="sat-2";
get_branch_name () {
    if [[ $(uname -n) == "Snow-White"* ]]; then
        echo "${SAT_1}"
    elif [[ $(uname -n) == "Astral-Canvas"* ]]; then
        echo "${SAT_2}"
    else
        echo "E"
    fi
}
DEVICE_BRANCH="$(get_branch_name)"
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
LOG="LOG - ${DEVICE_BRANCH}.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Start message
echo -e "${BLUE}=== Satellite Sync - ${DEVICE_BRANCH} ===${NC}"
cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found.${NC}"; exit 1; }

# 0. Ensure we are in the correct Satellite branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$DEVICE_BRANCH" ]; then
    echo -e "${YELLOW}Switching to branch $DEVICE_BRANCH...${NC}"
    git checkout "$DEVICE_BRANCH" || git checkout -b "$DEVICE_BRANCH"
fi

# 1. Commit Local Work
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Committing local changes...${NC}"
    git add .
    git commit -m "$DEVICE_BRANCH: Satellite Sync $(date "+%Y-%m-%d %H:%M")"
fi

# 2. Push to Satellite
echo -e "${BLUE}Pushing local state to $DEVICE_BRANCH...${NC}"
git push origin "$DEVICE_BRANCH"

# 3. Fetch Main
echo -e "${BLUE}Fetching Main...${NC}"
git fetch origin main

# Capture current hash (For logging purposes)
LOG_HASH=$(git rev-parse HEAD)

# 4. Attempt Merge of Main in DEVICE_BRANCH Satellite
# We check if Main has updates that conflict with DEVICE_BRANCH Satellite
CONFLICT_DETECTED=0


if git merge --no-commit --no-ff origin/main; then echo "OK"; else echo "Not OK"; fi
new thing
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
    echo "**Recovery Hash**: \`$SAFE_HASH\` in \`$MY_BRANCH\`" >> "$RECOVERY_LOG"
    echo "---" >> "$RECOVERY_LOG"
    
    # Commit the log so it survives the overwrite
    git add "$RECOVERY_LOG"
    git commit -m "$MY_BRANCH: Logged recovery receipt"
    
    echo -e "${RED}Overwriting local conflicts with Main...${NC}"
    sleep 2
fi

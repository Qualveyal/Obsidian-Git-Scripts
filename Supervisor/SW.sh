#!/bin/bash

# Configuration
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
JOURNAL_FILE="Conflict_Journal.md" # Owned by PC1
DATE=$(date "+%Y-%m-%d %H:%M:%S")
SW_BRANCH="main"
AC_BRANCH="pc2-satellite"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Master Sync (PC1) ===${NC}"

cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found!${NC}"; exit 1; }

# 1. Commit Local Changes (Ensures your clean work is saved)
if [[ -n $(git status -s) ]]; then
    echo -e "${YELLOW}Local changes detected. Committing...${NC}"
    git add .
    git commit -m "PC1: Manual Sync $DATE"
fi

# 2. Pull Remote Main (Strict Safety)
echo -e "${BLUE}Pulling latest Main...${NC}"
if ! git pull --ff-only origin main; then
    echo -e "${RED}CRITICAL: Main branch diverged. Fix manually before syncing.${NC}"
    exit 1
fi

# 3. Fetch PC2
echo -e "${BLUE}Fetching PC2 Satellite...${NC}"
git fetch origin pc2-satellite

# 4. Attempt Merge
if git merge --no-commit --no-ff origin/pc2-satellite > /dev/null 2>&1; then
    # --- SUCCESS ---
    echo -e "${GREEN}Merge Clean. Finalizing...${NC}"
    git commit -m "Merged PC2 into Main" > /dev/null
    
    echo -e "${BLUE}Pushing to GitHub...${NC}"
    git push origin main
    echo -e "${GREEN}✅ Sync Complete.${NC}"
else
    # --- CONFLICT ---
    echo -e "${RED}🛑 CONFLICT DETECTED! Merge Aborted.${NC}"
    
    # Capture details
    CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
    PC2_HASH=$(git rev-parse origin/pc2-satellite)
    
    # Reset
    git merge --abort
    
    # Write to Journal
    echo "" >> "$JOURNAL_FILE"
    echo "## Conflict Skipped - $DATE" >> "$JOURNAL_FILE"
    echo "Files skipped (PC2 content rejected):" >> "$JOURNAL_FILE"
    for file in $CONFLICT_FILES; do
        echo "- [[$file]]" >> "$JOURNAL_FILE"
    done
    echo "**Recovery Hash:** \`$PC2_HASH\` on branch \`$AC_BRANCH\`" >> "$JOURNAL_FILE"
    echo "---" >> "$JOURNAL_FILE"
    
    # Commit Journal
    git add "$JOURNAL_FILE"
    git commit -m "PC1: Logged conflict ($PC2_HASH)"
    
    # Push Main (Sends Local Changes + Journal)
    echo -e "${YELLOW}Pushing local changes + Journal to GitHub...${NC}"
    git push origin main
    
    echo -e "${GREEN}✅ Local changes synced. PC2 conflicts logged.${NC}"
fi
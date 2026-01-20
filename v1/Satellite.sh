#!/bin/bash

# Configurations
SATELLITES=("sat-1" "sat-2")
get_branch_name () {
    if [[ $(uname -n) == "Snow-White"* ]]; then
        echo "${SATELLITES[0]}"
    elif [[ $(uname -n) == "Astral-Canvas"* ]]; then
        echo "${SATELLITES[1]}"
    else
        echo "E"
    fi
}
DEVICE_BRANCH="$(get_branch_name)"
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
LOG="LOG - ${DEVICE_BRANCH}.md"

# Colors
BLACK='\033[0;30m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
WHITE='\033[0;37m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Start message
echo -e "${MAGENTA}=== Satellite Sync - ${DEVICE_BRANCH} ===${NC}"
cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found.${NC}"; exit 1; }

# 0 Ensure we are in the correct Satellite branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$DEVICE_BRANCH" ]; then
    echo -e "${BLUE}Switching to branch $DEVICE_BRANCH...${NC}"
    git checkout "$DEVICE_BRANCH" || git checkout -b "$DEVICE_BRANCH"
fi

# 1 Commit Local Work
if [[ -n $(git status -s) ]]; then
    echo -e "${BLUE}Committing local changes...${NC}"
    git add .
    git commit -m "$DEVICE_BRANCH: Satellite Sync $(date "+%Y-%m-%d %H:%M")"
fi

# 2 Push to Satellite
echo -e "${BLUE}Pushing local state to $DEVICE_BRANCH...${NC}"
git push origin "$DEVICE_BRANCH"

# 3 Fetch Main
echo -e "${BLUE}Fetching Main...${NC}"
git fetch origin main

# Capture current hash (For logging purposes)
LOG_HASH=$(git rev-parse HEAD)

# 4 Dry runing the merge of Main into local Satellite
# We check if Main has updates that conflict with local Satellite
echo -e "${BLUE}Attepting merge-tree...${NC}"
MERGE_OUTPUT=$(git merge-tree --write-tree "$DEVICE_BRANCH" main 2>&1)
CONFLICT_DETECTED=$? # The exit code for the last command.

# 5 Doing the merge of Main into local Satellite
if [[ $CONFLICT_DETECTED == 0 ]]; then
    # 5.1 Doing the merge of Main into local Satellite with no conflict
    echo -e "${YELLOW}CONFLICT FREE - Merging clean or with Fast-Forward...${NC}"
    git merge origin/main --no-edit -m "Sync from Main - No conflict"
    echo -e "${GREEN}MERGE COMPLETE - Merge main into local $DEVICE_BRANCH branch.${NC}"
elif [[ $CONFLICT_DETECTED == 1 ]]; then
    # 5.2 Doing the merge of Main into local Satellite with conflict
    # main branch's version overwrites the conflicts
    echo -e "${RED}CONFLICT DETECTED - Main overwrites $DEVICE_BRANCH.${NC}"
    CONFLICT_FILES=$(echo "$MERGE_OUTPUT" | grep "^CONFLICT" | sed 's/CONFLICT.*in //' | sed 's/.*/- [[&]]/')

    git merge origin/main -X theirs -m "Sync from Main - conflict logged"
    echo -e "${GREEN}MERGE COMPLETE - Merge main into local $DEVICE_BRANCH branch.${NC}"

    echo -e "${BLUE}Creating log...${NC}"
    COMMIT_HASH=$(git rev-parse HEAD)

    # 5.2.1 Write to the log file.
    echo "# $(date "+%Y-%m-%d")" >> "$LOG_FILE"
    echo "Merge: **main** → **$DEVICE_BRANCH**" >> "$LOG_FILE"
    echo "Conflict Resolution: **main** overwrote **$DEVICE_BRANCH**" >> "$LOG_FILE"
    echo "**$DEVICE_BRANCH** Commit Hash: $COMMIT_HASH" >> "$LOG_FILE"
    echo "$CONFLICT_FILES" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"

    # 5.2.2 Commit the log file
    echo -e "${BLUE}Comitting log to $DEVICE_BRANCH...${NC}"
    git add "$LOG_FILE"
    git commit -m "$DEVICE_BRANCH: Updated Log with conflict overwrites."
else
    echo -e "${RED}ERROR - Merge failed unexpectedly.${NC}"
    exit 1
fi

# 6 Push final result to Satellite.
echo -e "${BLUE}Pushing final state to $DEVICE_BRANCH...${NC}"
git push origin "$DEVICE_BRANCH"

echo -e "${GREEN}Satellite Sync Complete.${NC}"
# -r:raw | -s:silent, hide user input | -p: prompt | -n1:stop after 1 character
read -rsp "${MAGENTA}Press any key to finish.${NC}" -n1; echo "";


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
IGNORE_FILES=".obsidian/workspace.json"
LOG_FILE="LOG - Main.md"

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
echo -e "${MAGENTA}=== Main Sync ===${NC}"
cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found.${NC}"; exit 1; }

# 1 Ensure clean slate
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}ERROR - Uncommitted changes. Run Satellite sync first.${NC}"
    exit 1
fi

# 2 Fetch all remotes
echo -e "${BLUE}Fetching all remotes...${NC}"
git fetch --all

# 3 Switch to Main and pull it from the cloud to ensure it is the latest.
echo -e "${BLUE}Switching to Main...${NC}"
git switch main
git pull origin main

# 4 Dry run merge the Satellites into Main.
# We use a main-temp branch, started from main.
echo -e "${BLUE}Creating and Switching to Main-Temp...${NC}"
git switch -c main-temp main

# Ask how to deal with conflicts
echo -e "${CYAN}==========${NC}"
echo -e "${CYAN}Select Merge Strategy:${NC}"
echo "1) Manual Merge"
echo "2) Auto-Merge (Prefer Main-Temp, and log overrides to $LOG_FILE)"
echo "3) Abort Merge (Restore state)"
echo -e "${CYAN}==========${NC}"
read -p "Enter choice [1-3]: " CHOICE
echo -e "${CYAN}==========${NC}"

# Loop throught all the Satellites, starting from 1 to n.
for branch in "${SATELLITES[@]}"; do
    echo -e "---------------------------------"
    echo -e "${BLUE}Merge $branch into Main-Temp${NC}"

    # Test with merge-tree
    MERGE_OUTPUT=$(git merge-tree --write-tree Main-Temp "$branch" 2>&1)
    CONFLICT_DETECTED=$? # The exit code for the last command.

    if [[ $CONFLICT_DETECTED == 0 ]]; then
        # Doing the merge of Satellite into Main-Temp with no conflict
        echo -e "${YELLOW}CONFLICT FREE - Merging clean or with Fast-Forward...${NC}"
        git merge "origin/$branch" --no-edit
        echo -e "${GREEN}MERGE COMPLETE - Merge $branch into Main-Temp.${NC}"

    elif [[ $CONFLICT_DETECTED == 1 ]]; then
        # There is a conflict.
        
        # We chose to abort when there is a real conflict.
        if [[ $CHOICE == "3" ]]; then break; fi
        


        # 4.2 If the conflict is with an ignored file, then ignore it and take the main-temp version of it.
        CONFLICT_FILES=$(echo "$MERGE_OUTPUT" | grep "^CONFLICT" | sed 's/CONFLICT.*in //')
        for ignored in $IGNORE_FILES; do
            if [[ "$CONFLICT_FILES" == *"$ignored"* ]]; then
                tep

        # Option 2. Auto-Merge (Prefer Main-Temp, and log overrides to $LOG_FILE
        echo -e "${RED}CONFLICT DETECTED - Main-Temp overrules $branch.${NC}"
        git merge "origin/$branch" --no-edit -X ours
        echo -e "${GREEN}MERGE COMPLETE - Merge "origin/$branch" into local main-temp.${NC}"

        echo -e "${BLUE}Creating log...${NC}"
        COMMIT_HASH=$(git rev-parse HEAD)
        # Write to the log file.
        echo "# $(date "+%Y-%m-%d")" >> "$LOG_FILE"
        echo "Merge: $branch → **main**" >> "$LOG_FILE"
        echo "Conflict Resolution: **main** overtuled **$branch**" >> "$LOG_FILE"
        echo "**main** Commit Hash: $COMMIT_HASH" >> "$LOG_FILE"
        echo "$CONFLICT_FILES" >> "$LOG_FILE"
        echo "---" >> "$LOG_FILE"






    fi
done

# Option 3. Abort
git switch $DEVICE_BRANCH
git branch -D main-temp



---

show-options () {
    echo "Select Merge Strategy:"
    echo "1) Manual Merge"
    echo "2) Auto-Merge (Prefer Main-Temp, and log overrides to $LOG_FILE)"
    echo "3) Abort Merge (Restore state)"
    read -p "Enter choice [1-3]: " CHOICE
}

merge-options () {
    case $CHOICE in
    "1") # Manual fix
        echo -e "hi"
        ;;

    "2") # Automatic merge; for any conflict, we take main-temp's versions.
        echo -e "hi"
        ;;

    "3") # Abort
        echo -e "hi"
        ;;

    *)
        echo "bye"
        ;;
    esac
}
















git switch main
git branch -d temp-branch  # Use -D (capital) to force delete if unmerged

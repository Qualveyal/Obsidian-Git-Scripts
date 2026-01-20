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
# Specific files to auto-resolve in favor of Main (Space separated).
# IGNORE_FILES=(".obsidian/workspace.json" "B.md" "C.md")
IGNORE_FILES=(".obsidian/workspace.json")
LOG_FILE="LOG - Main.md"

# The "switch back to Device Satellite" function.
finishing-merge () {
    git switch $DEVICE_BRANCH
    git branch -D main-temp
}

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
while true; do
    echo -e "${CYAN}==========${NC}"
    echo -e "${CYAN}Select Merge Strategy:${NC}"
    echo "1) Manual Merge"
    echo "2) Auto-Merge (Prefer Main-Temp, and log overrides to $LOG_FILE)"
    echo "3) Abort Merge (Restore state)"
    echo -e "${CYAN}==========${NC}"
    read -p "Enter choice [1-3]: " CHOICE

    case $CHOICE in
        1|2|3)
            # Valid input! Break the loop to continue the script
            break
            ;;
        *)
            # Invalid input. The loop will repeat.
            echo -e "${RED}Error: '$CHOICE' is not a valid option. Please enter 1, 2, or 3.${NC}"
            ;;
    esac
done
echo -e "${CYAN}==========${NC}"

# Loop through all the Satellites, starting from 1 to n.
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
        CONFLICT_FILES=$(echo "$MERGE_OUTPUT" | grep "^CONFLICT" | sed 's/CONFLICT.*in //')
        
        # We chose to abort when there is a real conflict.
        if [[ $CHOICE == "3" ]]; then break; fi
        
        # Do the merge with the conflict.
        git merge "origin/$branch" --no-edit > /dev/null 2>&1

        # If the conflict is with an ignored file, then ignore it and take the main-temp version of it.
        echo -e "${YELLOW}Auto-resolving conflict for Ignored Files (Keeping Main-Temp version)...${NC}"
        for file in "{$IGNORE_FILES[@]}"; do
            if [[ "$CONFLICT_FILES" == *"$file"* ]]; then
                git restore --source=main-temp --staged --worktree "$file"
                RESOLVED_SOMETHING=1
            fi
        done

        # Check if any Real Conflicts remain
        CONFLICT_FILES=$(git diff --name-only --diff-filter=U)

        if [[ -z "$CONFLICTS" ]] && [[ $RESOLVED_SOMETHING == 1 ]]; then
            # We fixed everything, commit and move on
            git commit -m "Merged $branch (Auto-resolved Ignored File's conflicts, using Main version)" > /dev/null
            echo -e "${GREEN}Ignored File's conflict resolved automatically, using Main-Temp's version.${NC}"
        elif [ -n "$CONFLICTS" ]; then
            echo -e "${RED}There are real conflicts when merging $branch into Main-Temp${NC}"
            
            # Decide what to do based on the CHOICE
            case $CHOICE in
            # Manual fix
            "1") 
                echo -e "${YELLOW}You have chosen Merge Strategy 1${NC}"
                echo -e "${YELLOW}Manually resolve all conflicts.${NC}"
                echo -e "${YELLOW}Use \"git add\" and \"git commit\" before returning here.${NC}"
                echo -e "${YELLOW}==========${NC}"
                echo -e "${CONFLICTS}"
                echo -e "${YELLOW}==========${NC}"
                code $VAULT_PATH

                read -p "Press Enter when resolved..."

                if [[ -n $(git status -s) ]]; then
                    echo -e "${RED}Fix not committed. Exiting Main Sync...${NC}"
                    finishing-merge
                    exit 1
                fi  
                ;;

            # Automatic merge; for any conflict, we take main-temp's versions.
            # The new conflict files without the ignored ones.
            "2") 
                echo -e "${YELLOW}You have chosen Merge Strategy 2${NC}"
                echo -e "${YELLOW}Auto-resolving conflict by keeping Main-Temp version)...${NC}"
                
                for file in "{$IGNORE_FILES[@]}"; do
                    git restore --source=main-temp --staged --worktree "$file"
                done
                git commit -m "Merged $branch (Auto-resolved conflicts, using Main version)"
                echo -e "${GREEN}Conflict resolved automatically, using Main-Temp's version.${NC}"

                # Write to the log file.
                echo -e "${BLUE}Creating log...${NC}"
                COMMIT_HASH=$(git rev-parse HEAD)

                echo "# $(date "+%Y-%m-%d")" >> "$LOG_FILE"
                echo "Merge: $branch → **main**" >> "$LOG_FILE"
                echo "Conflict Resolution: **main** overruled **$branch**" >> "$LOG_FILE"
                echo "**main** Commit Hash: $COMMIT_HASH" >> "$LOG_FILE"
                echo "$CONFLICT_FILES" >> "$LOG_FILE"
                echo "---" >> "$LOG_FILE"

                # Commit the log file
                echo -e "${BLUE}Comitting log to $branch...${NC}"
                git add "$LOG_FILE"
                git commit -m "$branch: Updated Log with conflict overwrites."
                ;;

            # Abort
            "3")
                echo -e "${YELLOW}You have chosen Merge Strategy 3${NC}"
                echo -e "${YELLOW}There are real conflicts. Exiting Main Sync...${NC}"
                finishing-merge
                exit 1
                ;;
            esac
        fi
    fi
    echo -e "${GREEN}$branch has been commited into Main-Temp${NC}"
done

# 5. Merge Main-Temp into Main
echo -e "${BLUE}---------------------------------${NC}"
echo -e "${BLUE}Merging Main-Temp into Main...${NC}"
git switch main
git merge Main-Temp -m "Main Sync Complete"

# 6. Push New Main
echo -e "${BLUE}Pushing Main...${NC}"
git push origin main

# 6. Return to local Device Satellite and delete Main-Temp
echo -e "${BLUE}Returning to local branch ($DEVICE_BRANCH)...${NC}"
finishing-merge

# 7. Merge the new, synced Main into local Device Satellite
git switch $DEVICE_BRANCH
git merge main -m "Merge main into $DEVICE_BRANCH after a successful Main Sync."

echo -e "${GREEN}Main Sync Complete.${NC}"

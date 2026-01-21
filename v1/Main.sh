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
# Specific files to auto-resolve in favor of main (Space separated).
# IGNORE_FILES=(".obsidian/workspace.json" "B.md" "C.md")
IGNORE_FILES=(".obsidian/workspace.json")
LOG_FILE="LOG - Main.md"

# The "switch back to Device Satellite" function.
finishing-merge () {
    git reset --hard
    git switch $DEVICE_BRANCH
    git branch -D main-temp
}

# Colors
BLACK='\033[0;30m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
MAGENTA='\033[4;35m'
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
echo -e "${BLUE}Switching to main...${NC}"
git switch main
git pull origin main

# 4 Dry run merge the Satellites into main.
# We use a main-temp branch, started from main.
echo -e "${BLUE}Creating and Switching to main-temp...${NC}"
git switch -C main-temp main


# Ask how to deal with conflicts
while true; do
    echo -e "${CYAN}==========${NC}"
    echo -e "${CYAN}Select Merge Strategy:${NC}"
    echo "1) Manual Merge"
    echo "2) Auto-Merge (Prefer main-temp, and log overrides to $LOG_FILE)"
    echo -e "3) Abort Merge (Restore state) - ${CYAN}DEFAULT${NC}"
    echo -e "${CYAN}==========${NC}"
    read -p "Enter choice [1-3]: " CHOICE

    case $CHOICE in
        1|2|3)
            # Valid input! Break the loop to continue the script
            break
            ;;
        *)
            # Invalid input. Set to 3 for Abort
            CHOICE="3"
            break
            ;;
    esac
done
# If we want to abort, we go through with the Main Sync with C2 (auto), then cancel before merging main-temp.
ABORT=0
if [[ $CHOICE == "3" ]]; then CHOICE="2"; ABORT=1; fi

echo -e "${CYAN}==========${NC}"

# Loop through all the Satellites, starting from 1 to n.
for branch in "${SATELLITES[@]}"; do
    echo -e "---------------------------------"
    echo -e "${BLUE}Merging $branch into main-temp...${NC}"

    # Test with merge-tree
    MERGE_OUTPUT=$(git merge-tree --write-tree main-temp origin/"$branch" 2>&1)
    CONFLICT_DETECTED=$? # The exit code for the last command.
    

    if [[ $CONFLICT_DETECTED == 0 ]]; then
        # Doing the merge of Satellite into main-temp with no conflict
        echo -e "${YELLOW}CONFLICT FREE - No Merge or Merging clean or with Fast-Forward...${NC}"
        git merge "origin/$branch" --no-edit
        echo -e "${GREEN}MERGE COMPLETE - Merge $branch into main-temp.${NC}"

    elif [[ $CONFLICT_DETECTED == 1 ]]; then
        # There is a conflict.
        CONFLICT_FILES=$(echo "$MERGE_OUTPUT" | grep "^CONFLICT" | sed 's/CONFLICT.*in //')
        
        # Do the merge with the conflict.
        git merge "origin/$branch" --no-edit > /dev/null 2>&1

        # If the conflict is with an ignored file, then ignore it and take the main-temp version of it.
        RESOLVED_SOMETHING=0
        for file in "${IGNORE_FILES[@]}"; do
            if [[ "$CONFLICT_FILES" == *"$file"* ]]; then
                git restore --source=main-temp --staged --worktree "$file"
                RESOLVED_SOMETHING=1
            fi
        done
        # We actually resolved an ignored file.
        if [[ $RESOLVED_SOMETHING == 1 ]]; then
            echo -e "${YELLOW}Auto-resolved conflict for Ignored Files (Keeping main-temp version).${NC}"
        fi

        # Check if any Real Conflicts remain
        CONFLICT_FILES=$(git diff --name-only --diff-filter=U)
        # Make a list, empty string give a zero element list
        if [[ -z "$CONFLICT_FILES" ]]; then
            CONFLICT_LIST=()
        else
            mapfile -t CONFLICT_LIST <<< "$CONFLICT_FILES"
        fi

        # echo -e "---------------------------------"
        # echo "$CONFLICT_FILES"
        # echo -e "---------------------------------"


        if [[ ${#CONFLICT_LIST[@]} == 0 ]]; then # List empty
            # We fixed everything, commit and move on
            # Check if there was any conflict with the Ignored Files
            if [[ RESOLVED_SOMETHING == 1 ]]; then 
                MSG="Merged $branch (Auto-resolved Ignored File's conflicts, using Main version)"
            else
                MSG="Merged $branch (No conflict with Ignored Files)"
            fi

            # The commit
            git commit -m "${MSG}" > /dev/null
            echo -e "${GREEN}MERGE COMPLETE - Merged $branch without any real conflicts.${NC}"

        elif [[ ${#CONFLICT_LIST[@]} > 0 ]]; then # List not empty
            echo -e "${RED}There are real conflicts when merging $branch into main-temp${NC}"
            
            # Decide what to do based on the CHOICE
            case $CHOICE in
            # Manual fix
            "1") 
                echo -e "${YELLOW}You have chosen Merge Strategy 1${NC}"
                echo -e "${YELLOW}Manually resolve all conflicts.${NC}"
                echo -e "${YELLOW}Use \"git add\" and \"git commit\" before returning here.${NC}"
                echo -e "${YELLOW}==========${NC}"
                echo -e "${CONFLICT_LIST}"
                echo -e "${YELLOW}==========${NC}"
                code "$VAULT_PATH"

                echo -e "${MAGENTA}Press Enter to continue after manual commit...${NC}"
                echo -ne "${MAGENTA}If you do not commit, then the Sync will be Aborted.${NC}"
                read -rsn1; echo "";

                if [[ -n $(git status -s) ]]; then
                    echo -e "${RED}Fix not committed. Exiting Main Sync...${NC}"
                    finishing-merge
                    exit 1
                fi  
                ;;

            # Automatic merge; for any conflict, we take main-temp's versions.
            # The new conflict files without the ignored ones.
            "2") 
                echo -e "${YELLOW}You have chosen Merge Strategy 2 or 3${NC}"
                echo -e "${YELLOW}Auto-resolving conflict by keeping main-temp version...${NC}"
                
                for file in "${CONFLICT_LIST[@]}"; do
                    git restore --source=main-temp --staged --worktree "$file"
                done
                git commit -m "Merged $branch (Auto-resolved conflicts, using main version)"
                echo -e "${GREEN}MERGE COMPLETE - Conflict resolved automatically, using main-temp's version.${NC}"

                # Prepare for the log file.
                echo -e "${BLUE}Creating log...${NC}"
                COMMIT_HASH=$(git rev-parse HEAD)

                ##########
                # Write to the log file
                echo "# $(date "+%Y-%m-%d")" >> "$LOG_FILE"
                echo "Merge: $branch → **main**" >> "$LOG_FILE"
                echo "Conflict Resolution: **main** overruled **$branch**" >> "$LOG_FILE"
                echo "**main** Commit Hash: \`$COMMIT_HASH\`" >> "$LOG_FILE"

                # Loop through the list of conflicted files and make a formatted string
                # for this use case.
                for file in "${CONFLICT_LIST[@]}"; do
                    LOGGED_FILES="- $file"
                done
                echo "$LOGGED_FILES" >> "$LOG_FILE"

                echo "" >> "$LOG_FILE"
                echo "---" >> "$LOG_FILE"
                ##########

                # Commit the log file
                echo -e "${BLUE}Comitting log to main...${NC}"
                git add "$LOG_FILE"
                git commit -m "$branch: Updated Log with conflict overwrites."
                echo -e "${GREEN}LOG COMMIT COMPLETE - Logs for $branch has been committed into main-temp${NC}"
                ;;
            esac
        fi
    fi
done

# Check if we wish to abort
echo -e "---------------------------------"

if [[ $ABORT == 1 ]]; then
    echo -e "${YELLOW}You have chosen Merge Strategy 3 - Abort${NC}"

    # these are two functions so that it is easier to edit default Prompt of y and n.
    cancel_abort() {
        # Cancel Abort
        echo -e "---------------------------------"
        echo -e "${YELLOW}You have chosen to cancel the Abort${NC}"
        echo -e "${YELLOW}Main Sync will continue as Auto-Merge (2)${NC}"
    }
    do_abort() {
        # Abort
        echo -e "${YELLOW}Aborting Main Sync...${NC}"
        finishing-merge
        echo -ne "${MAGENTA}=== Press any key to finish. ===${NC}"
        # -r:raw | -s:silent, hide user input | -p: prompt | -n1:stop after 1 character
        read -rsn1; echo "";
        exit 1
    }

    # You have seen how the merge goes with main-temp
    # This prompt is to continue with the Sync and merge main-temp into main
    # This essentially make the Sync with Choice 2, auto0merge
    PROMPT="Y"
    read -p "Do you wish to cancel the Abort and do an Auto-Merge (2)? (Y/n): " PROMPT

    if [[ $PROMPT == "n" ]]; then 
        do_abort
    else
        cancel_abort
    fi

fi

# 5. Merge main-temp into Main
echo -e "${BLUE}Switching to main...${NC}"
git switch main
echo -e "${BLUE}Merging main-temp into main...${NC}"
git merge main-temp -m "Main Sync Complete"
echo -e "${GREEN}MERGE COMPLETE - main-temp has been merged into main.${NC}"

# 6. Push New main
echo -e "---------------------------------"
echo -e "${BLUE}Pushing main...${NC}"
git push origin main
echo -e "${GREEN}PUSH COMPLETE - local/main has been pushed into origin/main${NC}"

# 6. Return to local Device Satellite and delete main-temp
echo -e "---------------------------------"
echo -e "${BLUE}Returning to local branch ($DEVICE_BRANCH)...${NC}"
finishing-merge

# 7. Merge the new, synced main into local Device Satellite
git switch $DEVICE_BRANCH
git merge main -m "Merge main into $DEVICE_BRANCH after a successful Main Sync."
echo -e "${GREEN}MERGE COMPLETE - main has been merge into local/$DEVICE_BRANCH${NC}"

echo -e "---------------------------------"
echo -e "${GREEN}Main Sync Complete.${NC}"

echo -ne "${MAGENTA}=== Press any key to finish. ===${NC}"
# -r:raw | -s:silent, hide user input | -p: prompt | -n1:stop after 1 character
read -rsn1; echo "";

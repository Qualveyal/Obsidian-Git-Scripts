#!/bin/bash

# === CONFIGURATION ===
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
MY_LOCAL_BRANCH="sat-1"
SATELLITES=("sat-1" "sat-2")
# Specific files to auto-resolve in favor of Main (Space separated)
IGNORE_FILES=".obsidian/workspace.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Supervisor Session (Smart Mode) ===${NC}"
cd "$VAULT_PATH" || exit 1

# 1. Ensure clean slate
if [[ -n $(git status -s) ]]; then
    echo -e "${RED}Error: Uncommitted changes. Run daily sync first.${NC}"
    exit 1
fi

# 2. Update Knowledge
echo -e "${BLUE}Fetching all remotes...${NC}"
git fetch --all

# 3. Checkout Main
echo -e "${YELLOW}Switching to Main...${NC}"
git checkout main
git pull origin main

# 4. Loop through Satellites
for branch in "${SATELLITES[@]}"; do
    echo -e "---------------------------------"
    echo -e "${BLUE}Processing: $branch${NC}"
    
    CHANGES=$(git log main..origin/$branch --oneline)
    if [ -z "$CHANGES" ]; then
        echo -e "${GREEN}  Already up to date.${NC}"
        continue
    fi
    
    echo -e "${YELLOW}  Merging changes from $branch...${NC}"
    
    # Attempt Merge
    if git merge "origin/$branch" --no-edit > /dev/null 2>&1; then
        echo -e "${GREEN}  ✅ Success.${NC}"
    else
        # --- SMART CONFLICT RESOLUTION ---
        
        # 1. Attempt to auto-resolve specific config files
        # We check if the conflict list contains our ignored files
        RESOLVED_SOMETHING=0
        for ignored in $IGNORE_FILES; do
            if git diff --name-only --diff-filter=U | grep -q "$ignored"; then
                echo -e "${YELLOW}  ⚡ Auto-resolving conflict in $ignored (Keeping Main)...${NC}"
                # Checkout 'HEAD' means "Keep the version currently in Main"
                git checkout HEAD -- "$ignored"
                git add "$ignored"
                RESOLVED_SOMETHING=1
            fi
        done

        # 2. Check if any Real Conflicts remain
        CONFLICTS=$(git diff --name-only --diff-filter=U)
        
        if [ -z "$CONFLICTS" ] && [ $RESOLVED_SOMETHING -eq 1 ]; then
            # If we fixed everything, commit and move on
            git commit -m "Merged $branch (Auto-resolved config conflicts)" > /dev/null
            echo -e "${GREEN}  ✅ Config conflicts resolved automatically.${NC}"
            
        elif [ -n "$CONFLICTS" ]; then
            # Real conflicts still exist (Notes, etc.)
            echo -e "${RED}  🛑 MANUAL CONFLICT DETECTED!${NC}"
            echo -e "${YELLOW}  The following files need human attention:${NC}"
            echo "$CONFLICTS"
            echo -e "  1. Fix conflicts in Obsidian."
            echo -e "  2. Come back here and press Enter."
            
            read -p "Press Enter when resolved..."
            
            if [[ -n $(git status -s) ]]; then
                 echo -e "${RED}  Fix not committed. Exiting safety mode.${NC}"
                 exit 1
            fi
        fi
    fi
done

# 5. Push New Main
echo -e "---------------------------------"
echo -e "${BLUE}Pushing Main...${NC}"
git push origin main

# 6. Return to Local
echo -e "${YELLOW}Returning to local branch ($MY_LOCAL_BRANCH)...${NC}"
git checkout "$MY_LOCAL_BRANCH"
git merge main -m "Sync after Supervisor Session"

echo -e "${GREEN}✅ Supervisor Session Complete.${NC}"
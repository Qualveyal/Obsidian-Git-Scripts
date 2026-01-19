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
echo -e "${BLUE}=== Main Sync ===${NC}"
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
echo -e "${YELLOW}Switching to Main...${NC}"
git switch main
git pull origin main

# 4 Dry run merge the Satellites into Main.

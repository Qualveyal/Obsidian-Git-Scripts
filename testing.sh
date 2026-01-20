#!/bin/bash

# bash /home/qual/Code/Obsidian-Git-Scripts/testing.sh

SAT_1="sat-1"; SAT_2="sat-2"
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
LOG_FILE="./LOG.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

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

# echo -e "${BLACK}=== Press any key to finish. ===${NC}"
# echo -e "${BLUE}=== Press any key to finish. ===${NC}"
# echo -e "${GREEN}=== Press any key to finish. ===${NC}"
# echo -e "${CYAN}=== Press any key to finish. ===${NC}"
# echo -e "${RED}=== Press any key to finish. ===${NC}"
# echo -e "${MAGENTA}=== Press any key to finish. ===${NC}"
# echo -e "${WHITE}=== Press any key to finish. ===${NC}"
# echo -e "${YELLOW}=== Press any key to finish. ===${NC}"
# echo -e "${NC}=== Press any key to finish. ===${NC}"

CONFLICT_LIST=()

if [[ ${#CONFLICT_LIST[@]} == 0 ]]; then
    echo 1
elif [[ ${#CONFLICT_LIST[@]} > 0 ]]; then
    echo 5
fi
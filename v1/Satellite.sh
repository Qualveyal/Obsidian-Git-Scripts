#!/bin/bash

# Configurations
DEVICE_BRANCH="sat-1"
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
LOG="LOG - ${DEVICE_BRANCH}.md"

if [[ $(name -n) == "SNOW-WHITE"* ]]; then echo "OK"; elif [[ $(name -n) == "SNOW-WHITE"* ]]

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



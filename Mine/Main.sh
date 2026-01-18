#!/bin/bash

# === CONFIGURATION ===
VAULT_PATH="/home/qual/Code/Vault-Test-Git"
DEVICE_BRANCH="sat-1"
# Specific files to auto-resolve in favor of Main (Space separated)
IGNORE_FILES=".obsidian/workspace.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Main Sync Session ===${NC}"
cd "$VAULT_PATH" || { echo -e "${RED}Vault path not found!${NC}"; exit 1; }

# 1. Ensure clean slate
if [[ -n $(git status -s) ]]; then






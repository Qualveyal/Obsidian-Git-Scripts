#!/bin/bash
SAT_1="sat-1"; SAT_2="sat-2"
VAULT_PATH="/home/qual/Code/Vault-Test-Git/"
LOG_FILE="./LOG.log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

# Colors for Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

get_branch_name () {
    if [[ $(uname -n) == "Snow-White"* ]]; then
        echo "${SAT_1}"
    elif [[ $(uname -n) == "Astral-Canvas"* ]]; then
        echo "${SAT_2}"
    else
        echo "E"
    fi
}

result="$(get_branch_name)"
echo $result
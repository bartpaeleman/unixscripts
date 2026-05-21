#!/bin/bash

# ============================================================
# MASTER UPDATER
# Updates the Dev Tools suite in the current directory
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}=== Dev Tools Master Updater ===${NC}"
echo "This script will update the entire suite of tools in the current repository directory."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "Updating at: ${CYAN}${SCRIPT_DIR}${NC}"

# --- 1. PULL LATEST CHANGES ---
echo -e "\n${CYAN}Pulling latest changes from git...${NC}"

if [[ ! -d "$SCRIPT_DIR/.git" ]]; then
    echo -e "${RED}Error: Not a git repository.${NC}"
    echo "Please run this script from inside a git repository."
    exit 1
fi

(cd "$SCRIPT_DIR" && git pull)

echo -e "${GREEN}Files updated successfully.${NC}"

# --- 2. FINALIZE SETUP ---
echo -e "\n${CYAN}Finalizing Setup...${NC}"

# Make the updated dev-tools.sh executable
chmod +x "$SCRIPT_DIR/dev-tools.sh"

# Run the initialization script from the updated location
# This script natively calls setup-persistence.sh which asks about aliases
echo -e "Running initialization script from ${SCRIPT_DIR}..."
(cd "$SCRIPT_DIR" && ./dev-tools.sh)

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}         UPDATE COMPLETE                 ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "Location: ${SCRIPT_DIR}"
echo -e "The tool scripts have been updated, and your existing configuration was preserved."

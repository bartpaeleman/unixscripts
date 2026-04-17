#!/bin/bash

# ============================================================
# MASTER UPDATER
# Updates the Dev Tools suite to a custom location
# preserving .env settings in the target directory.
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
echo "This script will update the entire suite of tools in the specified location."
echo "Your existing .env configuration will be preserved."

# --- 1. DETERMINE UPDATE LOCATION ---
DEFAULT_DIR="$HOME/dev-tools"
read -p "Update location [${DEFAULT_DIR}]: " TARGET_DIR
TARGET_DIR="${TARGET_DIR:-$DEFAULT_DIR}"

# Expand tilde if present
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

echo -e "Updating at: ${CYAN}${TARGET_DIR}${NC}"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${RED}Error: Directory '$TARGET_DIR' does not exist.${NC}"
    echo "Please use install.sh for the initial installation."
    exit 1
fi

# --- 2. COPY FILES ---
echo -e "\n${CYAN}Updating files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use rsync if available, otherwise cp
if command -v rsync &> /dev/null; then
    # Exclude .git, install.sh, update.sh, and crucial config files
    rsync -av \
        --exclude='.git' \
        --exclude='install.sh' \
        --exclude='update.sh' \
        --exclude='.DS_Store' \
        --exclude='git-master/config/.env' \
        --exclude='intelmaster/config.json' \
        "$SCRIPT_DIR/" "$TARGET_DIR/"
else
    # Fallback to tar to preserve structure and exclude easily
    # Using tar pipeline to copy while excluding specific files
    (cd "$SCRIPT_DIR" && tar cf - \
        --exclude='.git' \
        --exclude='install.sh' \
        --exclude='update.sh' \
        --exclude='.DS_Store' \
        --exclude='git-master/config/.env' \
        --exclude='intelmaster/config.json' \
        . ) | (cd "$TARGET_DIR" && tar xvf -)
fi

echo -e "${GREEN}Files updated successfully.${NC}"

# --- 3. FINALIZE SETUP ---
echo -e "\n${CYAN}Finalizing Setup...${NC}"

# Make the updated dev-tools.sh executable
chmod +x "$TARGET_DIR/dev-tools.sh"

# Run the initialization script from the updated location
# This script natively calls setup-persistence.sh which asks about aliases
echo -e "Running initialization script from ${TARGET_DIR}..."
(cd "$TARGET_DIR" && ./dev-tools.sh)

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}         UPDATE COMPLETE                 ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "Location: ${TARGET_DIR}"
echo -e "The tool scripts have been updated, and your existing configuration was preserved."

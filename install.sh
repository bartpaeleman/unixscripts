#!/bin/bash

# ============================================================
# MASTER INSTALLER
# Installs the Dev Tools suite in the current directory
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}=== Dev Tools Master Installer ===${NC}"
echo "This script will initialize the tools in the current repository directory."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "Initializing tools at: ${CYAN}${SCRIPT_DIR}${NC}"

# --- 0. PREFERRED INSTALLATION DIRECTORY (QNAP) ---
if [[ -d "/share/Public" && "$SCRIPT_DIR" != "/share/Public/unixscripts" ]]; then
    echo -e "\n${YELLOW}QNAP detected: /share/Public is available.${NC}"
    echo "It is recommended to install persistent scripts in /share/Public/unixscripts"
    read -e -p "Move installation to /share/Public/unixscripts? (y/n): " MOVE_DIR

    if [[ "$MOVE_DIR" =~ ^[Yy]$ ]]; then
        TARGET_DIR="/share/Public/unixscripts"
        echo -e "${CYAN}Moving files to $TARGET_DIR...${NC}"
        mkdir -p "$TARGET_DIR"
        cp -a "$SCRIPT_DIR/." "$TARGET_DIR/"

        # Switch context to the new location
        SCRIPT_DIR="$TARGET_DIR"
        cd "$SCRIPT_DIR"
        echo -e "${GREEN}Successfully moved to $SCRIPT_DIR${NC}"
    fi
fi

# --- 1. CONFIGURE ENVIRONMENT (.env) ---
echo -e "\n${CYAN}Configuring Environment...${NC}"
ENV_DIR="$SCRIPT_DIR/git-master/config"
ENV_FILE="$ENV_DIR/.env"
ENV_EXAMPLE="$ENV_DIR/.env.example"

if [[ ! -f "$ENV_EXAMPLE" ]]; then
    echo -e "${RED}Error: .env.example not found in installation.${NC}"
    echo "Please check the repository integrity."
else
    NEEDS_CONFIG=false
    if [[ -f "$ENV_FILE" ]]; then
        echo -e "${YELLOW}.env file already exists in target.${NC}"
        read -e -p "Overwrite with new configuration? (y/n): " OVR_ENV
        if [[ "$OVR_ENV" =~ ^[Yy]$ ]]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            NEEDS_CONFIG=true
        fi
    else
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}Created .env from template.${NC}"
        NEEDS_CONFIG=true
    fi

    # Interactive Configuration
    if [[ "$NEEDS_CONFIG" == true && -f "$ENV_FILE" ]]; then
        echo -e "\n${YELLOW}Please enter your GitHub credentials for the tools:${NC}"

        read -e -p "GitHub Username: " GH_USER
        read -e -p "GitHub Email: " GH_EMAIL
        read -e -p "GitHub Token (ghp_...): " GH_TOKEN

        # Escape special chars for sed
        GH_USER=$(echo "$GH_USER" | sed 's/[\/&]/\\&/g')
        GH_EMAIL=$(echo "$GH_EMAIL" | sed 's/[\/&]/\\&/g')
        GH_TOKEN=$(echo "$GH_TOKEN" | sed 's/[\/&]/\\&/g')

        # GNU sed (QNAP)
            sed -i "s/^GITHUB_USERNAME=.*/GITHUB_USERNAME=\"$GH_USER\"/" "$ENV_FILE"
            if grep -q "^GITHUB_EMAIL=" "$ENV_FILE"; then
                sed -i "s/^GITHUB_EMAIL=.*/GITHUB_EMAIL=\"$GH_EMAIL\"/" "$ENV_FILE"
            else
                sed -i "/^GITHUB_USERNAME=.*/a GITHUB_EMAIL=\"$GH_EMAIL\"" "$ENV_FILE"
            fi
            sed -i "s/^GITHUB_TOKEN=.*/GITHUB_TOKEN=\"$GH_TOKEN\"/" "$ENV_FILE"

        git config --global user.name "$GH_USER"
        git config --global user.email "$GH_EMAIL"
        echo -e "${GREEN}Global Git configuration updated (user.name & user.email)${NC}"

        echo -e "${GREEN}Credentials updated in .env${NC}"
    fi
fi

# --- 2. FINALIZE SETUP ---
echo -e "\n${CYAN}Finalizing Setup...${NC}"

# Make the installed dev-tools.sh executable
chmod +x "$SCRIPT_DIR/dev-tools.sh"

# Run the initialization script from the new location
echo -e "Running initialization script from ${SCRIPT_DIR}..."
(cd "$SCRIPT_DIR" && ./dev-tools.sh)

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}       INSTALLATION COMPLETE             ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "Location: ${SCRIPT_DIR}"
echo -e "Tools have been installed and aliases configured."
echo -e "Please restart your terminal or run: ${BOLD}source ~/.bashrc${NC} (or your profile)"

#!/bin/bash

# ============================================================
# MASTER INSTALLER
# Installs the Dev Tools suite to a custom location
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
echo "This script will install the entire suite of tools to a location of your choice."

# --- 1. DETERMINE INSTALL LOCATION ---
DEFAULT_DIR="$HOME/dev-tools"
read -p "Install location [${DEFAULT_DIR}]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_DIR}"

# Expand tilde if present
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

echo -e "Installing to: ${CYAN}${INSTALL_DIR}${NC}"

if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${YELLOW}Warning: Directory '$INSTALL_DIR' already exists.${NC}"
    read -p "Continue and overwrite existing files? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
else
    mkdir -p "$INSTALL_DIR"
fi

# --- 2. COPY FILES ---
echo -e "\n${CYAN}Copying files...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use rsync if available, otherwise cp
if command -v rsync &> /dev/null; then
    rsync -av --exclude='.git' --exclude='install.sh' --exclude='.DS_Store' "$SCRIPT_DIR/" "$INSTALL_DIR/"
else
    # Fallback to cp
    cp -R "$SCRIPT_DIR/"* "$INSTALL_DIR/"
    # Clean up unwanted files that might have been copied
    rm -rf "$INSTALL_DIR/.git" "$INSTALL_DIR/install.sh"
fi

echo -e "${GREEN}Files copied successfully.${NC}"

# --- 3. CONFIGURE ENVIRONMENT (.env) ---
echo -e "\n${CYAN}Configuring Environment...${NC}"
ENV_DIR="$INSTALL_DIR/git-master/config"
ENV_FILE="$ENV_DIR/.env"
ENV_EXAMPLE="$ENV_DIR/.env.example"

if [[ ! -f "$ENV_EXAMPLE" ]]; then
    echo -e "${RED}Error: .env.example not found in installation.${NC}"
    echo "Please check the repository integrity."
else
    if [[ -f "$ENV_FILE" ]]; then
        echo -e "${YELLOW}.env file already exists in target.${NC}"
        read -p "Overwrite with new configuration? (y/n): " OVR_ENV
        if [[ "$OVR_ENV" =~ ^[Yy]$ ]]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
        fi
    else
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo -e "${GREEN}Created .env from template.${NC}"
    fi

    # Interactive Configuration
    if [[ -f "$ENV_FILE" ]]; then
        echo -e "\n${YELLOW}Please enter your GitHub credentials for the tools:${NC}"

        read -p "GitHub Username: " GH_USER
        read -p "GitHub Token (ghp_...): " GH_TOKEN

        # Escape special chars for sed
        GH_USER=$(echo "$GH_USER" | sed 's/[\/&]/\\&/g')
        GH_TOKEN=$(echo "$GH_TOKEN" | sed 's/[\/&]/\\&/g')

        if [[ "$(uname)" == "Darwin" ]]; then
            # macOS sed
            sed -i '' "s/^GITHUB_USERNAME=.*/GITHUB_USERNAME=\"$GH_USER\"/" "$ENV_FILE"
            sed -i '' "s/^GITHUB_TOKEN=.*/GITHUB_TOKEN=\"$GH_TOKEN\"/" "$ENV_FILE"
        else
            # GNU sed
            sed -i "s/^GITHUB_USERNAME=.*/GITHUB_USERNAME=\"$GH_USER\"/" "$ENV_FILE"
            sed -i "s/^GITHUB_TOKEN=.*/GITHUB_TOKEN=\"$GH_TOKEN\"/" "$ENV_FILE"
        fi

        echo -e "${GREEN}Credentials updated in .env${NC}"
    fi
fi

# --- 4. FINALIZE SETUP ---
echo -e "\n${CYAN}Finalizing Setup...${NC}"

# Make the installed dev-tools.sh executable
chmod +x "$INSTALL_DIR/dev-tools.sh"

# Run the initialization script from the new location
echo -e "Running initialization script from ${INSTALL_DIR}..."
(cd "$INSTALL_DIR" && ./dev-tools.sh)

echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}       INSTALLATION COMPLETE             ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "Location: ${INSTALL_DIR}"
echo -e "Tools have been installed and aliases configured."
echo -e "Please restart your terminal or run: ${BOLD}source ~/.bashrc${NC} (or your profile)"

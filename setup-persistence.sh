#!/bin/bash

# ============================================================
# PERSISTENCE SETUP
# Makes aliases permanent and sets up navigation shortcuts
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# SCRIPT_DIR is already calculated above
ENV_FILE="${SCRIPT_DIR}/git-master/config/.env"

echo -e "${CYAN}=== Persistence Setup ===${NC}"
echo "This script will create aliases to make tools available everywhere."
echo "It will also create shortcuts to jump to PROD, DEV, and TEST directories."

# Determine the directory where the scripts are currently located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "\nTarget directory for aliases: ${CYAN}${SCRIPT_DIR}${NC}"
read -p "Install/Update aliases to point to this location? (y/n): " INSTALL_ALIAS

if [[ "$INSTALL_ALIAS" != "y" ]]; then
    echo "Skipping persistence setup."
    exit 0
fi

# --- 0. CREDENTIAL HELPER SETUP ---
echo -e "\n${CYAN}Configuring Git Credentials...${NC}"
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    git config --global credential.helper osxkeychain
    echo -e "  ${GREEN}Set credential helper to osxkeychain (macOS)${NC}"
else
    # QNAP / Linux
    git config --global credential.helper 'cache --timeout=360000'
    echo -e "  ${GREEN}Set credential helper to cache (100 hours) (QNAP/Linux)${NC}"
fi

# --- 1. CONFIGURATION LOADING ---
# Try to load paths from git-master .env
PATH_PROD=""
PATH_DEV=""
PATH_TEST=""

if [[ -f "$ENV_FILE" ]]; then
    echo -e "\n${CYAN}Loading configuration from git-master/.env...${NC}"
    # Parse .env (simple grep)
    PATH_ROOT=$(grep "^PATH_ROOT=" "$ENV_FILE" | cut -d'"' -f2)
    PATH_PROD=$(grep "^PATH_PROD=" "$ENV_FILE" | cut -d'"' -f2)
    PATH_DEV=$(grep "^PATH_DEV=" "$ENV_FILE" | cut -d'"' -f2)
    PATH_TEST=$(grep "^PATH_TEST=" "$ENV_FILE" | cut -d'"' -f2)

    # If PROD/DEV/TEST not explicitly set, derive from ROOT
    [[ -z "$PATH_PROD" && -n "$PATH_ROOT" ]] && PATH_PROD="$PATH_ROOT"
    [[ -z "$PATH_DEV" && -n "$PATH_ROOT" ]] && PATH_DEV="$PATH_ROOT/DEV"
    [[ -z "$PATH_TEST" && -n "$PATH_ROOT" ]] && PATH_TEST="$PATH_ROOT/TEST"
fi

# --- 2. TOOL ALIASES ---
# Get absolute path of current directory
REPO_DIR="$SCRIPT_DIR"

ALIAS_BLOCK_TOOLS=$(cat <<EOF
# --- DEV TOOLS COLLECTION ALIASES ---
alias scriptmaster='"${REPO_DIR}/script-master.sh"'
alias devtools='"${REPO_DIR}/dev-tools.sh"'
alias gitmaster='"${REPO_DIR}/git-master/git-master.sh"'
alias dockermaster='"${REPO_DIR}/container-master/container-master.sh"'
alias netmaster='"${REPO_DIR}/network-master/network-master.sh"'
alias dbmaster='"${REPO_DIR}/db-tools/db-master.sh"'
alias scaffold='"${REPO_DIR}/web-scaffold/scaffold.sh"'
alias datamaster='"${REPO_DIR}/data-master/data-master.sh"'
alias filemaster='"${REPO_DIR}/file-master/file-master.sh"'
alias textmaster='"${REPO_DIR}/text-master/text-master.sh"'
alias videomaster='"${REPO_DIR}/video-master/video-master.sh"'
alias intelmaster='"${REPO_DIR}/intelmaster/threat-intel.sh"'
alias persis='"${REPO_DIR}/setup-persistence.sh"'
# ------------------------------------
EOF
)

# --- 3. PROFILE DETECTION ---
PROFILES=()
[[ -f "$HOME/.bashrc" ]] && PROFILES+=("$HOME/.bashrc")
[[ -f "$HOME/.zshrc" ]] && PROFILES+=("$HOME/.zshrc")
[[ -f "$HOME/.profile" ]] && PROFILES+=("$HOME/.profile")
[[ -f "$HOME/.bash_profile" ]] && PROFILES+=("$HOME/.bash_profile")

# QNAP / System wide fallback
if [[ -w "/etc/profile" ]]; then
    PROFILES+=("/etc/profile")
fi

if [[ ${#PROFILES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}Could not detect any existing writable shell profile.${NC}"

    # Detect shell
    CURRENT_SHELL=$(basename "$SHELL")
    PREFERRED_PROFILE=""

    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        PREFERRED_PROFILE="$HOME/.zshrc"
    elif [[ "$CURRENT_SHELL" == "bash" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            PREFERRED_PROFILE="$HOME/.bash_profile"
        else
            PREFERRED_PROFILE="$HOME/.bashrc"
        fi
    else
        PREFERRED_PROFILE="$HOME/.profile"
    fi

    echo -e "Detected shell: ${CYAN}$CURRENT_SHELL${NC}"
    echo -e "Preferred profile: ${CYAN}$PREFERRED_PROFILE${NC}"

    read -p "Create $PREFERRED_PROFILE? (y/n): " CREATE_PROF
    if [[ "$CREATE_PROF" == "y" ]]; then
        touch "$PREFERRED_PROFILE"
        PROFILES+=("$PREFERRED_PROFILE")
        echo -e "${GREEN}Created $PREFERRED_PROFILE${NC}"
    else
        echo "Please add the aliases manually."
        exit 1
    fi
fi

# --- 4. NAVIGATION ALIASES ---
# Check existing profiles for any already configured paths
EXISTING_PROD=""
EXISTING_DEV=""
EXISTING_TEST=""

if [[ ${#PROFILES[@]} -gt 0 ]]; then
    for prof in "${PROFILES[@]}"; do
        # Extract existing alias paths if they exist
        if grep -q "alias prd=" "$prof"; then
            FOUND_PROD=$(grep "alias prd=" "$prof" | tail -1 | cut -d'"' -f2 | cut -d"'" -f2)
            [[ -n "$FOUND_PROD" ]] && EXISTING_PROD="$FOUND_PROD"
        fi
        if grep -q "alias dev=" "$prof"; then
            FOUND_DEV=$(grep "alias dev=" "$prof" | tail -1 | cut -d'"' -f2 | cut -d"'" -f2)
            [[ -n "$FOUND_DEV" ]] && EXISTING_DEV="$FOUND_DEV"
        fi
        if grep -q "alias tst=" "$prof"; then
            FOUND_TEST=$(grep "alias tst=" "$prof" | tail -1 | cut -d'"' -f2 | cut -d"'" -f2)
            [[ -n "$FOUND_TEST" ]] && EXISTING_TEST="$FOUND_TEST"
        fi
    done
fi

# Override with existing profile values if not found in .env, or use existing profile values as fallback
[[ -z "$PATH_PROD" && -n "$EXISTING_PROD" ]] && PATH_PROD="$EXISTING_PROD"
[[ -z "$PATH_DEV" && -n "$EXISTING_DEV" ]] && PATH_DEV="$EXISTING_DEV"
[[ -z "$PATH_TEST" && -n "$EXISTING_TEST" ]] && PATH_TEST="$EXISTING_TEST"

echo -e "\n${CYAN}Configuring Navigation Aliases...${NC}"
read -p "Enter path for PROD [${PATH_PROD}]: " INPUT_PROD
PATH_PROD="${INPUT_PROD:-$PATH_PROD}"

read -p "Enter path for DEV [${PATH_DEV}]: " INPUT_DEV
PATH_DEV="${INPUT_DEV:-$PATH_DEV}"

read -p "Enter path for TEST [${PATH_TEST}]: " INPUT_TEST
PATH_TEST="${INPUT_TEST:-$PATH_TEST}"


ALIAS_BLOCK_NAV="# --- NAVIGATION ALIASES ---"
if [[ -n "$PATH_PROD" ]]; then
    ALIAS_BLOCK_NAV="${ALIAS_BLOCK_NAV}
alias prd='cd \"${PATH_PROD}\"'"
    echo -e "  Adding alias: ${GREEN}prd -> ${PATH_PROD}${NC}"
fi
if [[ -n "$PATH_DEV" ]]; then
    ALIAS_BLOCK_NAV="${ALIAS_BLOCK_NAV}
alias dev='cd \"${PATH_DEV}\"'"
    echo -e "  Adding alias: ${GREEN}dev -> ${PATH_DEV}${NC}"
fi
if [[ -n "$PATH_TEST" ]]; then
    ALIAS_BLOCK_NAV="${ALIAS_BLOCK_NAV}
alias tst='cd \"${PATH_TEST}\"'"
    echo -e "  Adding alias: ${GREEN}tst -> ${PATH_TEST}${NC}"
fi
ALIAS_BLOCK_NAV="${ALIAS_BLOCK_NAV}
# ----------------------------"

# --- 5. INSTALLATION ---
if [[ ${#PROFILES[@]} -gt 0 ]]; then
    echo -e "\n${CYAN}Detected Profiles:${NC}"
    for prof in "${PROFILES[@]}"; do
        echo -e "  - $prof"
    done

    echo -e "\nInstalling aliases..."

    for prof in "${PROFILES[@]}"; do
        echo -e "\nProcessing profile: ${CYAN}$prof${NC}"

        # Clean up old blocks if present
        # Using a loop to handle multiple blocks or partial updates logic
        # Ideally, check if block exists, prompt to update.

        # Tools Block
        if grep -q "# --- DEV TOOLS COLLECTION ALIASES ---" "$prof"; then
             # Remove old block (Portable sed: delete range)
             sed -i.bak '/# --- DEV TOOLS COLLECTION ALIASES ---/,/# ------------------------------------/d' "$prof"
             rm -f "$prof.bak"
             echo -e "  ${YELLOW}Updated existing Tools Aliases.${NC}"
        else
             echo -e "  ${GREEN}Added Tools Aliases.${NC}"
        fi
        echo "$ALIAS_BLOCK_TOOLS" >> "$prof"

        # Navigation Block
        if grep -q "# --- NAVIGATION ALIASES ---" "$prof"; then
             sed -i.bak '/# --- NAVIGATION ALIASES ---/,/# ----------------------------/d' "$prof"
             rm -f "$prof.bak"
             echo -e "  ${YELLOW}Updated existing Navigation Aliases.${NC}"
        else
             echo -e "  ${GREEN}Added Navigation Aliases.${NC}"
        fi
        echo "$ALIAS_BLOCK_NAV" >> "$prof"

    done

    echo -e "\n${GREEN}Setup complete.${NC}"
    echo -e "Please run ${BOLD}source <profile>${NC} or restart your shell to apply changes."
fi

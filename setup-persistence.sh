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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/git-master/config/.env"

echo -e "${CYAN}=== Persistence Setup ===${NC}"
echo "This script will create aliases to make tools available everywhere."
echo "It will also create shortcuts to jump to PROD, DEV, and TEST directories."

read -p "Do you want to install aliases? (y/n): " INSTALL_ALIAS

if [[ "$INSTALL_ALIAS" != "y" ]]; then
    echo "Skipping persistence setup."
    exit 0
fi

# --- 1. TOOL ALIASES ---
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
alias persis='"${REPO_DIR}/setup-persistence.sh"'
# ------------------------------------
EOF
)

# --- 2. NAVIGATION ALIASES ---
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

# Fallback prompts if paths are missing
if [[ -z "$PATH_PROD" ]]; then
    echo -e "${YELLOW}Could not detect PATH_PROD automatically.${NC}"
    read -p "Enter path for PROD (leave empty to skip alias): " PATH_PROD
fi
if [[ -z "$PATH_DEV" ]]; then
    read -p "Enter path for DEV (leave empty to skip alias): " PATH_DEV
fi
if [[ -z "$PATH_TEST" ]]; then
    read -p "Enter path for TEST (leave empty to skip alias): " PATH_TEST
fi

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

# --- 4. INSTALLATION ---
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

#!/bin/bash

# ============================================================
# DEV TOOLS MASTER SETUP
# Initializes permissions for all tools in the repository
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}=== Dev Tools Initialization ===${NC}"
echo "Setting executable permissions..."

# List of directories to process
DIRS=("git-master" "web-scaffold" "db-tools" "container-master" "network-master" "cleanup")

COUNT=0

for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "Processing ${YELLOW}$dir${NC}..."

        # Make shell scripts executable
        find "$dir" -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  + {}" \;

        # Make python scripts executable (optional, but good for direct invocation)
        find "$dir" -name "*.py" -type f -exec chmod +x {} \; -exec echo "  + {}" \;

        ((COUNT++))
    else
        echo -e "${YELLOW}Warning: Directory '$dir' not found.${NC}"
    fi
done

echo -e "\n${GREEN}✓ Initialization complete.${NC}"

# --- PERSISTENCE SETUP ---
echo -e "\n${CYAN}=== Persistence Setup ===${NC}"
echo "This step will create aliases to make tools available everywhere."
read -p "Do you want to install aliases? (y/n): " INSTALL_ALIAS

if [[ "$INSTALL_ALIAS" == "y" ]]; then
    # Detect Profile
    PROFILE=""
    if [[ -f "$HOME/.zshrc" ]]; then
        PROFILE="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        PROFILE="$HOME/.bashrc"
    elif [[ -f "/etc/profile" ]] && [[ -w "/etc/profile" ]]; then
        # Fallback for QNAP if running as admin/root
        PROFILE="/etc/profile"
    fi

    if [[ -z "$PROFILE" ]]; then
        echo -e "${YELLOW}Could not detect a writable shell profile (.zshrc, .bashrc).${NC}"
        echo "Please add the aliases manually."
    else
        echo -e "Target Profile: ${YELLOW}$PROFILE${NC}"

        # Get absolute path of current directory
        REPO_DIR="$(pwd)"

        # Define Aliases
        cat >> "$PROFILE" <<EOF

# --- DEV TOOLS COLLECTION ALIASES ---
alias devtools='${REPO_DIR}/dev-tools.sh'
alias gitmaster='${REPO_DIR}/git-master/git-master.sh'
alias dockermaster='${REPO_DIR}/container-master/container-master.sh'
alias netmaster='${REPO_DIR}/network-master/network-master.sh'
alias dbmaster='${REPO_DIR}/db-tools/db-master.sh'
alias cleanmaster='${REPO_DIR}/cleanup/cleanup-master.sh'
alias scaffold='${REPO_DIR}/web-scaffold/scaffold.sh'
# ------------------------------------
EOF
        echo -e "${GREEN}✓ Aliases added to $PROFILE${NC}"
        echo -e "Please run: ${BOLD}source $PROFILE${NC} to activate them."
    fi
else
    echo "Skipping persistence setup."
fi

echo -e "\n${GREEN}All done!${NC}"

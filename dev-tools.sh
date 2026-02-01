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
    # Get absolute path of current directory
    REPO_DIR="$(pwd)"
    ALIAS_BLOCK=$(cat <<EOF

# --- DEV TOOLS COLLECTION ALIASES ---
alias devtools='"${REPO_DIR}/dev-tools.sh"'
alias gitmaster='"${REPO_DIR}/git-master/git-master.sh"'
alias dockermaster='"${REPO_DIR}/container-master/container-master.sh"'
alias netmaster='"${REPO_DIR}/network-master/network-master.sh"'
alias dbmaster='"${REPO_DIR}/db-tools/db-master.sh"'
alias cleanmaster='"${REPO_DIR}/cleanup/cleanup-master.sh"'
alias scaffold='"${REPO_DIR}/web-scaffold/scaffold.sh"'
# ------------------------------------
EOF
)

    # Detect all potential profiles
    PROFILES=()
    [[ -f "$HOME/.bashrc" ]] && PROFILES+=("$HOME/.bashrc")
    [[ -f "$HOME/.zshrc" ]] && PROFILES+=("$HOME/.zshrc")
    [[ -f "$HOME/.profile" ]] && PROFILES+=("$HOME/.profile")

    # QNAP / System wide fallback
    if [[ -w "/etc/profile" ]]; then
        PROFILES+=("/etc/profile")
    fi

    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}Could not detect any writable shell profile (.bashrc, .zshrc, .profile).${NC}"
        echo "Please add the aliases manually."
    else
        echo -e "\n${CYAN}Detected Profiles:${NC}"
        for prof in "${PROFILES[@]}"; do
            echo -e "  - $prof"
        done

        echo -e "\nInstalling aliases to all detected profiles..."

        for prof in "${PROFILES[@]}"; do
            # Check if alias already exists to avoid duplication
            if grep -q "DEV TOOLS COLLECTION ALIASES" "$prof"; then
                echo -e "${YELLOW}Aliases already present in $prof. Skipping.${NC}"
            else
                echo "$ALIAS_BLOCK" >> "$prof"
                echo -e "${GREEN}✓ Added to $prof${NC}"
            fi
        done

        echo -e "\nPlease run ${BOLD}source <profile>${NC} or restart your shell."
    fi
else
    echo "Skipping persistence setup."
fi

echo -e "\n${GREEN}All done!${NC}"

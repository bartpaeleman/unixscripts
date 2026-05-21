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
DIRS=("git-master" "web-scaffold" "db-tools" "container-master" "file-master" "text-master" "data-master" "system-manager")

COUNT=0

for dir in "${DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        echo -e "Processing ${YELLOW}$dir${NC}..."

        # Make shell scripts executable
        find "$dir" -name "*.sh" -type f -exec chmod +x {} \; -exec echo "  + {}" \;

        # Make python scripts executable (optional, but good for direct invocation)
        find "$dir" -name "*.py" -type f -exec chmod +x {} \; -exec echo "  + {}" \;

        ((COUNT++)) || true
    else
        echo -e "${YELLOW}Warning: Directory '$dir' not found.${NC}"
    fi
done

echo -e "\n${GREEN}✓ Initialization complete.${NC}"

# --- PERSISTENCE SETUP ---
# Handled by separate script
if [[ -f "./setup-persistence.sh" ]]; then
    chmod +x ./setup-persistence.sh
    ./setup-persistence.sh
else
    echo -e "${YELLOW}Warning: setup-persistence.sh not found.${NC}"
fi

# --- PYTHON SETUP ---
echo -e "\n${CYAN}=== Python Environment Setup ===${NC}"
read -e -p "Check for Python configuration? (y/n): " CHECK_PYTHON

if [[ "$CHECK_PYTHON" == "y" ]]; then
    # Ensure profiles are detected if not already done
    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        [[ -f "$HOME/.bashrc" ]] && PROFILES+=("$HOME/.bashrc")
        [[ -f "$HOME/.zshrc" ]] && PROFILES+=("$HOME/.zshrc")
        [[ -f "$HOME/.profile" ]] && PROFILES+=("$HOME/.profile")
        if [[ -w "/etc/profile" ]]; then
            PROFILES+=("/etc/profile")
        fi
    fi

    if [[ ${#PROFILES[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No writable profiles found. Skipping Python setup.${NC}"
    else
        # 1. Detect current status
        if command -v python3 &>/dev/null; then
            CUR_PY=$(command -v python3)
            echo -e "Current python3: ${GREEN}$CUR_PY${NC}"
        else
            echo -e "Current python3: ${RED}Not in PATH${NC}"
        fi

        # 2. Check for common QNAP location
        QNAP_PY_DIR="/share/CACHEDEV1_DATA/.samba_python3/Python3/bin"
        FOUND_QNAP_PY=""

        if [[ -d "$QNAP_PY_DIR" ]]; then
            # Look for python3 or python3.*
            for py in "$QNAP_PY_DIR"/python3*; do
                if [[ -x "$py" ]]; then
                    FOUND_QNAP_PY="$py"
                    break
                fi
            done
        fi

        if [[ -n "$FOUND_QNAP_PY" ]]; then
            echo -e "Found QNAP Python: ${GREEN}$FOUND_QNAP_PY${NC}"
        fi

        # 3. Ask user
        echo -e "\nConfiguring persistence..."
        TARGET_PY=""

        if [[ -n "$FOUND_QNAP_PY" ]]; then
            read -e -p "Use found QNAP Python ($FOUND_QNAP_PY)? (y/n): " USE_QNAP
            if [[ "$USE_QNAP" == "y" ]]; then
                TARGET_PY="$FOUND_QNAP_PY"
            fi
        fi

        if [[ -z "$TARGET_PY" ]]; then
            read -e -p "Enter path to python3 executable (empty to skip): " MANUAL_PY
            TARGET_PY="$MANUAL_PY"
        fi

        # 4. Apply
        if [[ -n "$TARGET_PY" ]]; then
            PY_DIR=$(dirname "$TARGET_PY")

            CMD_EXPORT="export PATH=\"$PY_DIR:\$PATH\""
            CMD_ALIAS_1="alias python='$TARGET_PY'"
            CMD_ALIAS_2="alias python3='$TARGET_PY'"

            for prof in "${PROFILES[@]}"; do
                echo -e "Updating ${CYAN}$prof${NC}..."

                if ! grep -q "# --- PYTHON SETUP ---" "$prof"; then
                    echo "" >> "$prof"
                    echo "# --- PYTHON SETUP ---" >> "$prof"
                    echo "$CMD_EXPORT" >> "$prof"
                    echo "$CMD_ALIAS_1" >> "$prof"
                    echo "$CMD_ALIAS_2" >> "$prof"
                    echo "# --------------------" >> "$prof"
                    echo -e "  ${GREEN}Added Python configuration${NC}"
                else
                    echo -e "  ${YELLOW}Python config already exists${NC}"
                fi
            done
            echo -e "${GREEN}Python setup complete.${NC}"
        else
            echo "Skipping Python setup."
        fi
    fi
fi

echo -e "\n${GREEN}All done!${NC}"

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
DIRS=("git-master" "web-scaffold" "db-tools" "container-master" "network-master" "data-master" "file-master" "text-master")

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
echo -e "\n${CYAN}=== Persistence Setup ===${NC}"
echo "This step will create aliases to make tools available everywhere."
read -p "Do you want to install aliases? (y/n): " INSTALL_ALIAS

if [[ "$INSTALL_ALIAS" == "y" ]]; then
    # Get absolute path of current directory
    REPO_DIR="$(pwd)"
    ALIAS_BLOCK=$(cat <<EOF

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
# ------------------------------------
EOF
)

    # Detect all potential profiles
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
        fi
    fi

    if [[ ${#PROFILES[@]} -gt 0 ]]; then
        echo -e "\n${CYAN}Detected Profiles:${NC}"
        for prof in "${PROFILES[@]}"; do
            echo -e "  - $prof"
        done

        echo -e "\nInstalling aliases..."

        # Define aliases to check/install
        # Using parallel arrays for Bash 3 compatibility (QNAP/macOS)
        # declare -A not supported on older bash versions

        for prof in "${PROFILES[@]}"; do
            echo -e "\nProcessing profile: ${CYAN}$prof${NC}"

            # Check for existing block
            HAS_BLOCK=false
            if grep -q "# --- DEV TOOLS COLLECTION ALIASES ---" "$prof"; then
                HAS_BLOCK=true
            fi

            # Check for conflicts
            CONFLICT=false
            if [[ "$HAS_BLOCK" == "true" ]]; then
                 # If block exists, we assume we manage it.
                 # But let's check if the content is exactly what we want.
                 # Actually, simpler: just ask if we should update.
                 echo -e "  ${YELLOW}Existing alias block found.${NC}"
                 read -p "  Update/Overwrite all Dev Tools aliases? (y/n): " UPDATE_ALL
                 if [[ "$UPDATE_ALL" != "y" ]]; then
                     echo "  Skipped."
                     continue
                 fi

                 # Remove old block (Portable sed: delete range)
                 sed -i.bak '/# --- DEV TOOLS COLLECTION ALIASES ---/,/# ------------------------------------/d' "$prof"
                 rm -f "$prof.bak"
            fi

            # Append new block
            echo "$ALIAS_BLOCK" >> "$prof"
            echo -e "  ${GREEN}Aliases installed/updated.${NC}"
        done

        echo -e "\nPlease run ${BOLD}source <profile>${NC} or restart your shell."
    fi
else
    echo "Skipping persistence setup."
fi

# --- PYTHON SETUP ---
echo -e "\n${CYAN}=== Python Environment Setup ===${NC}"
read -p "Check for Python configuration? (y/n): " CHECK_PYTHON

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
            read -p "Use found QNAP Python ($FOUND_QNAP_PY)? (y/n): " USE_QNAP
            if [[ "$USE_QNAP" == "y" ]]; then
                TARGET_PY="$FOUND_QNAP_PY"
            fi
        fi

        if [[ -z "$TARGET_PY" ]]; then
            read -p "Enter path to python3 executable (empty to skip): " MANUAL_PY
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

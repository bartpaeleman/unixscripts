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
        # 1. Detect current status and gather paths
        FOUND_PATHS=()

        # Gather from PATH using which
        if command -v python &>/dev/null; then
            FOUND_PATHS+=("$(command -v python)")
        fi
        if command -v python3 &>/dev/null; then
            FOUND_PATHS+=("$(command -v python3)")
        fi

        # 2. Check common QNAP locations
        COMMON_PATHS=(
            "/share/CACHEDEV1_DATA/.qpkg/Python3/bin/python3"
            "/share/CACHEDEV1_DATA/.samba_python3/Python3/bin/python3"
            "/opt/bin/python3"
            "/usr/local/bin/python3"
        )

        for p in "${COMMON_PATHS[@]}"; do
            if [[ -x "$p" ]]; then
                FOUND_PATHS+=("$p")
            fi
        done

        # Extended search in .qpkg if none of the above are valid/exist
        if [[ ${#FOUND_PATHS[@]} -eq 0 && -d "/share/CACHEDEV1_DATA/.qpkg" ]]; then
            echo -e "${YELLOW}Searching for python3 in .qpkg...${NC}"
            QPKG_PY=$(find "/share/CACHEDEV1_DATA/.qpkg" -maxdepth 4 -name "python3" -type f -executable 2>/dev/null | head -n 1)
            [[ -n "$QPKG_PY" ]] && FOUND_PATHS+=("$QPKG_PY")
        fi

        # Remove duplicates
        UNIQUE_PATHS=()
        for p in "${FOUND_PATHS[@]}"; do
            # Check if path is already in unique array
            is_dup=false
            for u in "${UNIQUE_PATHS[@]}"; do
                if [[ "$p" == "$u" ]]; then
                    is_dup=true
                    break
                fi
            done
            if [[ "$is_dup" == false && -x "$p" ]]; then
                UNIQUE_PATHS+=("$p")
            fi
        done

        # 3. Present Menu
        echo -e "\n${CYAN}Discovered Python Paths:${NC}"
        if [[ ${#UNIQUE_PATHS[@]} -gt 0 ]]; then
            for i in "${!UNIQUE_PATHS[@]}"; do
                echo -e "  ${GREEN}$((i+1))) ${UNIQUE_PATHS[$i]}${NC}"
            done
        else
            echo -e "  ${RED}No Python installations automatically found.${NC}"
        fi

        echo -e "\nConfiguring persistence..."
        TARGET_PY=""

        if [[ ${#UNIQUE_PATHS[@]} -gt 0 ]]; then
            echo "Enter a number (1-${#UNIQUE_PATHS[@]}) to select a path,"
            echo "or press M to type it manually, or Enter to skip."
            read -e -p "Choice: " PY_CHOICE

            if [[ "$PY_CHOICE" =~ ^[0-9]+$ ]] && [ "$PY_CHOICE" -ge 1 ] && [ "$PY_CHOICE" -le "${#UNIQUE_PATHS[@]}" ]; then
                TARGET_PY="${UNIQUE_PATHS[$((PY_CHOICE-1))]}"
            elif [[ "$PY_CHOICE" =~ ^[mM]$ ]]; then
                read -e -p "Enter manual path to python executable: " TARGET_PY
            fi
        else
            read -e -p "Enter manual path to python executable (empty to skip): " TARGET_PY
        fi

        # 4. Apply
        if [[ -n "$TARGET_PY" ]]; then
            PY_DIR=$(dirname "$TARGET_PY")

            CMD_EXPORT="export PATH=\"$PY_DIR:\$PATH\""
            CMD_ALIAS_1="alias python='$TARGET_PY'"
            CMD_ALIAS_2="alias python3='$TARGET_PY'"

            # Define alias store
            if [[ -d "/share/Public" ]]; then
                ALIAS_STORE="/share/Public/.bash_aliases"
            else
                ALIAS_STORE="/share/CACHEDEV1_DATA/.bash_aliases"
            fi

            echo -e "Updating ${CYAN}$ALIAS_STORE${NC}..."
            touch "$ALIAS_STORE"

            if ! grep -q "# --- PYTHON SETUP ---" "$ALIAS_STORE"; then
                echo "" >> "$ALIAS_STORE"
                echo "# --- PYTHON SETUP ---" >> "$ALIAS_STORE"
                echo "$CMD_EXPORT" >> "$ALIAS_STORE"
                echo "$CMD_ALIAS_1" >> "$ALIAS_STORE"
                echo "$CMD_ALIAS_2" >> "$ALIAS_STORE"
                echo "# --------------------" >> "$ALIAS_STORE"
                echo -e "  ${GREEN}Added Python configuration to aliases${NC}"
            else
                echo -e "  ${YELLOW}Python config already exists in aliases${NC}"
            fi

            # Clean up legacy python config in profiles if present
            for prof in "${PROFILES[@]}"; do
                if grep -q "# --- PYTHON SETUP ---" "$prof"; then
                     sed '/# --- PYTHON SETUP ---/,/# --------------------/d' "$prof" > "${prof}.tmp" && mv "${prof}.tmp" "$prof"
                     echo -e "  ${YELLOW}Removed legacy inline Python config from ${prof}.${NC}"
                fi
            done

            echo -e "${GREEN}Python setup complete.${NC}"
        else
            echo "Skipping Python setup."
        fi
    fi
fi

echo -e "\n${GREEN}All done!${NC}"

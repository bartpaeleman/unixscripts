#!/bin/bash

# ============================================================
# FORMAT MASTER TOOL
# Data Conversion & Normalization
# ============================================================

# set -e disabled for interactive menu

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

check_deps() {
    python3 "$SCRIPT_DIR/converter.py" check
    pause
}

convert_file() {
    echo -e "\n${CYAN}=== Convert File ===${NC}"
    read -p "Input File Path: " IN_FILE
    if [[ ! -f "$IN_FILE" ]]; then
        echo "File not found."
        pause
        return
    fi

    read -p "Output File Path: " OUT_FILE

    python3 "$SCRIPT_DIR/converter.py" convert "$IN_FILE" "$OUT_FILE"
    pause
}

normalize_dataset() {
    echo -e "\n${CYAN}=== Normalize Dataset ===${NC}"
    read -p "Input CSV Path: " IN_FILE
    if [[ ! -f "$IN_FILE" ]]; then
        echo "File not found."
        pause
        return
    fi

    read -p "Output CSV Path: " OUT_FILE

    python3 "$SCRIPT_DIR/converter.py" normalize "$IN_FILE" "$OUT_FILE"
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}FORMAT MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Check Dependencies"
    echo "2) Convert File (CSV <-> JSON, etc.)"
    echo "3) Normalize CSV (Clean empty rows/spaces)"
    echo "X) Exit"

    read -p "Select: " choice
    case $choice in
        1) check_deps ;;
        2) convert_file ;;
        3) normalize_dataset ;;
        [Xx]) exit 0 ;;
    esac
done

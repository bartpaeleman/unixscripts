#!/bin/bash

# ============================================================
# CLEANUP MASTER TOOL
# System Junk Removal & Deduplication
# ============================================================

# Disable set -e for interactive menu
# set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

clean_junk() {
    echo -e "\n${CYAN}=== System Junk Cleaner ===${NC}"
    read -p "Target Directory [.]: " TARGET
    TARGET=${TARGET:-"."}

    if [[ ! -d "$TARGET" ]]; then
        echo "Error: Directory not found."
        pause
        return
    fi

    echo "Scanning..."
    # Count files
    COUNT_DS=$(find "$TARGET" -name ".DS_Store" | wc -l)
    COUNT_THUMBS=$(find "$TARGET" -name "Thumbs.db" | wc -l)
    COUNT_U=$(find "$TARGET" -name "._*" | wc -l)
    TOTAL=$((COUNT_DS + COUNT_THUMBS + COUNT_U))

    if [[ $TOTAL -eq 0 ]]; then
        echo -e "${GREEN}No junk files found.${NC}"
    else
        echo -e "${YELLOW}Found: $TOTAL files (.DS_Store, Thumbs.db, ._*)${NC}"
        read -p "Delete all? (y/n): " CONFIRM
        if [[ "$CONFIRM" == "y" ]]; then
            find "$TARGET" -name ".DS_Store" -delete
            find "$TARGET" -name "Thumbs.db" -delete
            find "$TARGET" -name "._*" -delete
            echo -e "${GREEN}Cleaned.${NC}"
        else
            echo "Cancelled."
        fi
    fi
    pause
}

find_dupes() {
    echo -e "\n${CYAN}=== Duplicate Finder ===${NC}"
    if ! command -v python3 &> /dev/null; then
        echo "Python3 required."
        pause
        return
    fi

    read -p "Target Directory [.]: " TARGET
    TARGET=${TARGET:-"."}

    python3 "$SCRIPT_DIR/dedupe.py" "$TARGET"
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}CLEANUP MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Clean System Junk (.DS_Store, etc)"
    echo "2) Find Duplicate Files (MD5 Check)"
    echo "X) Exit"

    read -p "Select: " choice
    case $choice in
        1) clean_junk ;;
        2) find_dupes ;;
        [Xx]) exit 0 ;;
    esac
done

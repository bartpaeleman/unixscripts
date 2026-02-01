#!/bin/bash

# ============================================================
# FILE MASTER TOOL
# Bulk Rename, Archive, Cleanup
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

bulk_rename() {
    echo -e "\n${CYAN}=== Bulk Rename ===${NC}"
    read -p "Target Directory: " DIR
    if [[ ! -d "$DIR" ]]; then
        echo "Directory not found."
        pause
        return
    fi

    echo "Regex Support (Python re)"
    echo "Example: 'image_(\d+)' -> 'img_\1'"
    read -r -p "Pattern (Regex): " PATTERN
    read -p "Replacement: " REPLACE

    echo -e "\n${YELLOW}Previewing changes...${NC}"
    python3 "$SCRIPT_DIR/file_manager.py" rename "$DIR" "$PATTERN" "$REPLACE"

    echo ""
    read -p "Apply changes? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        python3 "$SCRIPT_DIR/file_manager.py" rename "$DIR" "$PATTERN" "$REPLACE" --run
    fi
    pause
}

create_struct() {
    echo -e "\n${CYAN}=== Create Structure ===${NC}"
    echo "Provide a text file where each line is a directory path to create."
    read -p "Template File Path: " TMPL

    if [[ ! -f "$TMPL" ]]; then
        echo "File not found."
        pause
        return
    fi

    python3 "$SCRIPT_DIR/file_manager.py" structure "$TMPL"
    pause
}

archive_dir() {
    echo -e "\n${CYAN}=== Archive Directory ===${NC}"
    read -p "Directory to Archive: " DIR

    if [[ ! -d "$DIR" ]]; then
        echo "Directory not found."
        pause
        return
    fi

    echo "1) Zip"
    echo "2) Tar.gz"
    read -p "Select Format: " FMT_CHOICE

    TYPE="zip"
    if [[ "$FMT_CHOICE" == "2" ]]; then
        TYPE="tar"
    fi

    python3 "$SCRIPT_DIR/file_manager.py" archive "$DIR" --type "$TYPE"
    pause
}

cleanup_dir() {
    echo -e "\n${CYAN}=== Cleanup Directory ===${NC}"
    read -p "Target Directory: " DIR

    if [[ ! -d "$DIR" ]]; then
        echo "Directory not found."
        pause
        return
    fi

    read -p "Delete Duplicates (MD5 check)? (y/n): " DEL_DUPES
    read -p "Delete Empty Directories? (y/n): " DEL_EMPTY

    ARGS=""
    if [[ "$DEL_DUPES" == "y" ]]; then ARGS="$ARGS --dupes"; fi
    if [[ "$DEL_EMPTY" == "y" ]]; then ARGS="$ARGS --empty"; fi

    echo -e "\n${YELLOW}Previewing...${NC}"
    python3 "$SCRIPT_DIR/file_manager.py" cleanup "$DIR" $ARGS

    read -p "Execute cleanup? (y/n): " CONFIRM
    if [[ "$CONFIRM" == "y" ]]; then
        python3 "$SCRIPT_DIR/file_manager.py" cleanup "$DIR" $ARGS --run
    fi
    pause
}

compare_files() {
    echo -e "\n${CYAN}=== Compare Files ===${NC}"
    read -p "File 1: " F1
    read -p "File 2: " F2

    if [[ ! -f "$F1" ]] || [[ ! -f "$F2" ]]; then
        echo "One or both files not found."
        pause
        return
    fi

    python3 "$SCRIPT_DIR/file_manager.py" compare "$F1" "$F2"
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}FILE MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Bulk Rename (Regex)"
    echo "2) Create Directory Structure (from template)"
    echo "3) Archive Directory (Zip/Tar)"
    echo "4) Cleanup (Duplicates/Empty Dirs)"
    echo "5) Compare Files"
    echo "X) Exit"

    read -p "Select: " choice
    case $choice in
        1) bulk_rename ;;
        2) create_struct ;;
        3) archive_dir ;;
        4) cleanup_dir ;;
        5) compare_files ;;
        [Xx]) exit 0 ;;
    esac
done

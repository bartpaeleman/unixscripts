#!/bin/bash

# ============================================================
# CSV MASTER TOOL
# Advanced CSV Manipulation & Viewing
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

check_python() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: python3 is required for this tool.${NC}"
        pause
        return 1
    fi
    return 0
}

view_csv() {
    check_python || return
    echo -e "\n${CYAN}=== CSV Table Viewer ===${NC}"
    read -p "CSV File Path: " FILE

    if [[ ! -f "$FILE" ]]; then
        echo "File not found."
        pause
        return
    fi

    python3 "$SCRIPT_DIR/csv_utils.py" view "$FILE" | less -S
}

convert_delim() {
    check_python || return
    echo -e "\n${CYAN}=== Convert Delimiter ===${NC}"
    read -p "Input CSV Path: " IN_FILE

    if [[ ! -f "$IN_FILE" ]]; then
        echo "File not found."
        pause
        return
    fi

    read -p "Output CSV Path: " OUT_FILE

    echo "Common delimiters: , ; | or \t (tab)"
    read -p "New Delimiter: " NEW_DELIM

    if [[ -z "$NEW_DELIM" ]]; then
        echo "Delimiter required."
        pause
        return
    fi

    python3 "$SCRIPT_DIR/csv_utils.py" convert "$IN_FILE" "$OUT_FILE" --new "$NEW_DELIM"
    pause
}

to_json() {
    check_python || return
    echo -e "\n${CYAN}=== CSV to JSON Export ===${NC}"
    read -p "Input CSV Path: " IN_FILE

    if [[ ! -f "$IN_FILE" ]]; then
        echo "File not found."
        pause
        return
    fi

    read -p "Output JSON Path: " OUT_FILE

    python3 "$SCRIPT_DIR/csv_utils.py" json "$IN_FILE" "$OUT_FILE"
    pause
}

count_rows() {
    echo -e "\n${CYAN}=== Row Counter ===${NC}"
    read -p "CSV File Path: " FILE
    if [[ -f "$FILE" ]]; then
        COUNT=$(wc -l < "$FILE")
        # Subtract header usually? Let's just give raw lines
        echo -e "${GREEN}Total Lines: $COUNT${NC}"
    else
        echo "File not found."
    fi
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}CSV MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) View as ASCII Table (Scrollable)"
    echo "2) Convert Delimiter (e.g., ; to ,)"
    echo "3) Export to JSON"
    echo "4) Count Rows (wc -l)"
    echo "X) Exit"

    read -p "Select: " choice
    case $choice in
        1) view_csv ;;
        2) convert_delim ;;
        3) to_json ;;
        4) count_rows ;;
        [Xx]) exit 0 ;;
    esac
done

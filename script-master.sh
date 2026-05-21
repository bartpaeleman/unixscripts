#!/bin/bash

# ============================================================
# SCRIPT MASTER CONTROL PANEL
# Central Hub for All Development Tools
# ============================================================

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

# --- TOOL LAUNCHERS ---

launch_git() {
    bash "$SCRIPT_DIR/git-master/git-master.sh"
}

launch_web() {
    bash "$SCRIPT_DIR/web-scaffold/scaffold.sh"
}

launch_db() {
    bash "$SCRIPT_DIR/db-tools/db-master.sh"
}

launch_container() {
    bash "$SCRIPT_DIR/container-master/container-master.sh"
}

launch_data() {
    bash "$SCRIPT_DIR/data-master/data-master.sh"
}

launch_file() {
    bash "$SCRIPT_DIR/file-master/file-master.sh"
}

launch_text() {
    bash "$SCRIPT_DIR/text-master/text-master.sh"
}

setup_env() {
    bash "$SCRIPT_DIR/dev-tools.sh"
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}SCRIPT MASTER CONTROL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Container Master (Docker Management)"
    echo "2) Git Master       (Workflow & Branching)"
    echo "3) Text Master      (Stats, Diff, Merge)"
    echo "4) DB Master        (Database Tools)"
    echo "5) File Master      (Rename, Archive, Cleanup)"
    echo "6) Data Master      (Convert/View CSV,JSON,XML)"
    echo "7) Web Scaffold     (Project Generator)"
    echo -e "-----------------------------------"
    echo "S) Setup Environment (Permissions & Aliases)"
    echo "X) Exit"

    read -e -p "Select Tool: " choice
    case $choice in
        1) launch_container ;;
        2) launch_git ;;
        3) launch_text ;;
        4) launch_db ;;
        5) launch_file ;;
        6) launch_data ;;
        7) launch_web ;;
        [sS]) setup_env ;;
        [xX]) exit 0 ;;
        *) echo "Invalid option." ; pause ;;
    esac
done

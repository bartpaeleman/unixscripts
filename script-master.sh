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

launch_net() {
    bash "$SCRIPT_DIR/network-master/network-master.sh"
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

launch_video() {
    bash "$SCRIPT_DIR/video-master/video-master.sh"
}

launch_intel() {
    bash "$SCRIPT_DIR/intelmaster/threat-intel.sh"
    pause
}

edit_intel_config() {
    local config_file="$SCRIPT_DIR/intelmaster/config.json"
    if [ -f "$config_file" ]; then
        ${EDITOR:-vi} "$config_file"
    else
        echo -e "${RED}Error: $config_file not found.${NC}"
        pause
    fi
}

add_intel_source() {
    local config_file="$SCRIPT_DIR/intelmaster/config.json"
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: $config_file not found.${NC}"
        pause
        return
    fi

    echo -e "\n${CYAN}Add New Threat Intel Source${NC}"
    read -p "Name (e.g. My RSS Feed): " src_name
    read -p "URL: " src_url
    read -p "Type (e.g. rss, json, cisa_kev): " src_type

    if [[ -z "$src_name" || -z "$src_url" || -z "$src_type" ]]; then
        echo -e "${RED}All fields are required. Aborting.${NC}"
        pause
        return
    fi

    # Append to JSON using python3 to ensure syntax validity
    SRC_NAME="$src_name" SRC_URL="$src_url" SRC_TYPE="$src_type" python3 -c "
import json, sys, os
config_path = '$config_file'
try:
    with open(config_path, 'r') as f:
        data = json.load(f)

    if 'sources' not in data:
        data['sources'] = []

    data['sources'].append({
        'name': os.environ.get('SRC_NAME', ''),
        'url': os.environ.get('SRC_URL', ''),
        'type': os.environ.get('SRC_TYPE', '')
    })

    with open(config_path, 'w') as f:
        json.dump(data, f, indent=2)
    print('Successfully added source.')
except Exception as e:
    print(f'Error updating config: {e}')
    sys.exit(1)
"
    pause
}

intelmaster_menu() {
    while true; do
        clear
        echo -e "${CYAN}===================================${NC}"
        echo -e "          ${CYAN}INTEL MASTER${NC}"
        echo -e "${CYAN}===================================${NC}"
        echo "1) Run Threat Intel Aggregator"
        echo "2) Edit Config (config.json)"
        echo "3) Add New Source to Config"
        echo -e "-----------------------------------"
        echo "B) Back to Main Menu"

        read -p "Select Option: " choice
        case $choice in
            1) launch_intel ;;
            2) edit_intel_config ;;
            3) add_intel_source ;;
            [bB]) break ;;
            *) echo "Invalid option." ; pause ;;
        esac
    done
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
    echo "1) Git Master       (Workflow & Branching)"
    echo "2) Web Scaffold     (Project Generator)"
    echo "3) DB Master        (Database Tools)"
    echo "4) Container Master (Docker Management)"
    echo "5) Network Master   (Port Scan & Utils)"
    echo "6) Data Master      (Convert/View CSV,JSON,XML)"
    echo "7) File Master      (Rename, Archive, Cleanup)"
    echo "8) Text Master      (Stats, Diff, Merge)"
    echo "9) Video Master     (Download & Clip Videos)"
    echo "10) Intel Master    (Threat Intelligence Menu)"
    echo -e "-----------------------------------"
    echo "S) Setup Environment (Permissions & Aliases)"
    echo "X) Exit"

    read -p "Select Tool: " choice
    case $choice in
        1) launch_git ;;
        2) launch_web ;;
        3) launch_db ;;
        4) launch_container ;;
        5) launch_net ;;
        6) launch_data ;;
        7) launch_file ;;
        8) launch_text ;;
        9) launch_video ;;
        10) intelmaster_menu ;;
        [sS]) setup_env ;;
        [xX]) exit 0 ;;
        *) echo "Invalid option." ; pause ;;
    esac
done

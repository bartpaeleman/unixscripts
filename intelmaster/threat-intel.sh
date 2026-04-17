#!/usr/bin/env bash
# threat-intel.sh
# Aggregates Threat Intelligence from various sources, parses them,
# and generates a matching report via an embedded Python analyzer.

set -euo pipefail

# Define paths
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/config.json"
SRC_DIR="$SCRIPT_DIR/src"
ASSETS_DIR="$SCRIPT_DIR/assets"
PUBLIC_DIR="$SCRIPT_DIR/public"
ANALYZER_SCRIPT="$SRC_DIR/analyzer.py"
CSS_FILE="$ASSETS_DIR/style.css"

# Temporary directory for raw downloads
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Ensure public directory exists
mkdir -p "$PUBLIC_DIR"

# Ensure secure permissions on config if it exists
if [ -f "$CONFIG_FILE" ]; then
    chmod 600 "$CONFIG_FILE"
else
    echo "Error: config.json not found in $SCRIPT_DIR" >&2
    exit 1
fi

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

pause() {
    read -p "Press Enter to continue..."
}

run_aggregator() {
    echo "[*] Threat Intel Aggregator Started: $(date)"

    # Fetch data
    echo "[*] Fetching threat intelligence sources..."
    while IFS='|' read -r index url; do
        if [ -z "$url" ]; then
            continue
        fi

        echo "    -> Downloading from: $url"

        # Secure download with curl
        # -s: silent
        # -L: follow redirects
        # -A: set realistic User-Agent to prevent 403 blocks
        # -m: max time 30s
        raw_file="$TMP_DIR/source_${index}.raw"
        if ! curl -s -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36" \
             -m 30 "$url" -o "$raw_file"; then
            echo "    [!] Warning: Failed to download $url" >&2
        fi
    done < <(get_sources)

    # Run Python Analyzer
    echo "[*] Analyzing data and generating report..."
    if [ -f "$ANALYZER_SCRIPT" ]; then
        REPORT_PATH=$(python3 "$ANALYZER_SCRIPT" "$CONFIG_FILE" "$TMP_DIR" "$PUBLIC_DIR" "$CSS_FILE")

        if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ]; then
            echo "[+] Report successfully generated: $REPORT_PATH"
            # Set proper permissions for the output directory/files
            chmod 755 "$PUBLIC_DIR"
            chmod 644 "$REPORT_PATH"
        else
            echo "[-] Failed to generate report." >&2
            exit 1
        fi
    else
        echo "[-] Error: Analyzer script not found at $ANALYZER_SCRIPT" >&2
        exit 1
    fi

    echo "[*] Done."
    pause
}

edit_intel_config() {
    if [ -f "$CONFIG_FILE" ]; then
        ${EDITOR:-vi} "$CONFIG_FILE"
    else
        echo -e "${RED}Error: $CONFIG_FILE not found.${NC}"
        pause
    fi
}

add_intel_source() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}Error: $CONFIG_FILE not found.${NC}"
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
try:
    with open('$CONFIG_FILE', 'r') as f:
        config = json.load(f)

    new_src = {
        'name': os.environ['SRC_NAME'],
        'url': os.environ['SRC_URL'],
        'type': os.environ['SRC_TYPE'],
        'active': True
    }

    if 'sources' not in config:
        config['sources'] = []

    config['sources'].append(new_src)

    with open('$CONFIG_FILE', 'w') as f:
        json.dump(config, f, indent=2)
    print('\nSuccessfully added source to config.json')
except Exception as e:
    print(f'Error updating config: {e}')
    sys.exit(1)
"
    pause
}

manage_feeds_list() {
    echo -e "\n${CYAN}Manage Feeds from List${NC}"
    echo "Please provide the path to a text file or CSV containing feed URLs."
    echo "Lines starting with '#' or '-' will be deactivated."
    echo "Plain URLs will be activated/added."
    read -e -p "File Path: " list_path

    if [[ -f "$list_path" ]]; then
        python3 "$SCRIPT_DIR/manage_feeds.py" "$CONFIG_FILE" "$list_path"
    else
        echo -e "${RED}Error: File not found: $list_path${NC}"
    fi
    pause
}

interactive_toggle() {
    python3 "$SCRIPT_DIR/interactive_toggle.py" "$CONFIG_FILE"
    pause
}

install_intel_deps() {
    echo -e "\n${CYAN}Installing Intel Master Dependencies...${NC}"
    echo "This will try to install missing Python packages like 'python-dateutil'."

    if command -v python3 &> /dev/null; then
        echo "Attempting installation via python3 -m pip..."
        if python3 -m pip install --user python-dateutil; then
            echo -e "${GREEN}Dependencies installed successfully.${NC}"
        else
            echo -e "${YELLOW}pip not found. Attempting to bootstrap pip...${NC}"
            if python3 -m ensurepip; then
                python3 -m pip install --user python-dateutil
                echo -e "${GREEN}Dependencies installed successfully.${NC}"
            else
                echo -e "${RED}Error: Failed to install pip or dependencies.${NC}"
            fi
        fi
    elif command -v pip3 &> /dev/null; then
        pip3 install --user python-dateutil
        echo -e "${GREEN}Dependencies installed successfully.${NC}"
    else
        echo -e "${RED}Error: Neither python3 nor pip3 is available in your PATH.${NC}"
    fi
    pause
}

intelmaster_menu() {
    while true; do
        clear
        echo -e "${CYAN}===================================${NC}"
        echo -e "          ${CYAN}INTEL MASTER${NC}"
        echo -e "${CYAN}===================================${NC}"
        echo "1) Run Threat Intel Aggregator (All/Default)"
        echo "2) Run Threat Intel Aggregator (General Security Info)"
        echo "3) Run Threat Intel Aggregator (Patches & Vulnerabilities)"
        echo "4) Run Threat Intel Aggregator (Other Cyber Sec Topics)"
        echo "5) Edit Config (config.json)"
        echo "6) Add New Source to Config"
        echo "7a) Manage Feeds from List (Text File/CSV)"
        echo "7b) Toggle Feeds Interactively"
        echo "8) Install Dependencies (Python)"
        echo -e "-----------------------------------"
        echo "X) Exit"

        read -p "Select Option: " choice
        case $choice in
            1) export INTEL_FILTER="default"; run_aggregator ;;
            2) export INTEL_FILTER="general"; run_aggregator ;;
            3) export INTEL_FILTER="patches"; run_aggregator ;;
            4) export INTEL_FILTER="other"; run_aggregator ;;
            5) edit_intel_config ;;
            6) add_intel_source ;;
            7a) manage_feeds_list ;;
            7b) interactive_toggle ;;
            8) install_intel_deps ;;
            [xX]) break ;;
            *) echo "Invalid option." ; pause ;;
        esac
    done
}

# Function to extract JSON array elements using Python (avoids missing jq dependency)
get_sources() {
    python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
        for i, src in enumerate(data.get('sources', [])):
            if src.get('active', True):
                print(f\"{i}|{src.get('url', '')}\")
except Exception as e:
    sys.exit(1)
"
}

# Start the menu
intelmaster_menu

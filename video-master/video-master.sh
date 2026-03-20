#!/bin/bash

# ============================================================
# VIDEO MASTER
# Video Download & Segment Extraction Toolkit
# ============================================================

# Interactive scripts should generally avoid set -e to prevent menu crashes
# However, we can use set -u to catch unbound variables
set -u

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.yt_clip_config"
DEFAULT_FALLBACK="$HOME/Downloads"

# Ensure we have our default vars
DEFAULT_DIR=""
USER_DIR=""
OUTPUT_DIR=""

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

check_dependencies() {
    local missing=0

    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}Error: yt-dlp is not installed.${NC}"
        missing=1
    fi

    if ! command -v ffmpeg &> /dev/null; then
        echo -e "${RED}Error: ffmpeg is not installed.${NC}"
        missing=1
    fi

    if [ $missing -eq 1 ]; then
        echo -e "\n${YELLOW}Please install the missing dependencies:${NC}"
        echo -e "${CYAN}Mac (Homebrew):${NC}"
        echo "brew install yt-dlp ffmpeg"
        echo -e "\n${CYAN}Linux (APT):${NC}"
        echo "sudo apt install yt-dlp ffmpeg"
        echo -e "\n${CYAN}Python (pip):${NC}"
        echo "pip install yt-dlp"
        echo "ffmpeg still needs to be installed via system package manager."

        echo -e "\nPress Enter to return to main menu..."
        read -r
        return 1
    fi
    return 0
}

# --- DIRECTORY MANAGEMENT ---
load_default_dir() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

save_default_dir() {
    echo "DEFAULT_DIR=\"$1\"" > "$CONFIG_FILE"
}

configure_output_dir() {
    load_default_dir

    if [ -n "${DEFAULT_DIR:-}" ]; then
        BASE_DIR="$DEFAULT_DIR"
    else
        BASE_DIR="$DEFAULT_FALLBACK"
    fi

    echo -e "${CYAN}Current default directory: ${BASE_DIR}${NC}"
    read -p "Enter target directory (ENTER = $BASE_DIR): " USER_DIR

    if [ -z "$USER_DIR" ]; then
        USER_DIR="$BASE_DIR"
    fi

    mkdir -p "$USER_DIR"
    save_default_dir "$USER_DIR"
    OUTPUT_DIR="$USER_DIR"

    echo -e "📁 Output directory set to: ${GREEN}$OUTPUT_DIR${NC}"
}

get_url() {
    echo ""
    read -p "Enter Video URL: " URL
    if [ -z "$URL" ]; then
        echo -e "${RED}❌ No URL provided. Returning to menu.${NC}"
        return 1
    fi
    return 0
}

# --- DOWNLOAD FUNCTIONS ---
download_standard() {
    configure_output_dir
    get_url || return
    echo -e "\n${CYAN}⬇️ Downloading video...${NC}"
    yt-dlp -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Done!${NC}"
    pause
}

download_best() {
    configure_output_dir
    get_url || return
    echo -e "\n${CYAN}⬇️ Downloading best quality video + audio...${NC}"
    yt-dlp -f "bestvideo+bestaudio" --merge-output-format mp4 -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Done!${NC}"
    pause
}

download_audio() {
    configure_output_dir
    get_url || return
    echo -e "\n${CYAN}🎵 Downloading audio only (MP3)...${NC}"
    yt-dlp -x --audio-format mp3 -o "$OUTPUT_DIR/%(title)s.%(ext)s" "$URL"
    echo -e "\n${GREEN}✅ Done!${NC}"
    pause
}

list_formats() {
    get_url || return
    echo -e "\n${CYAN}📋 Fetching available formats...${NC}"
    yt-dlp -F "$URL"
    pause
}

download_clip() {
    configure_output_dir
    get_url || return

    read -p "Enter start time (e.g., 00:01:30) or leave blank: " START
    read -p "Enter end time (e.g., 00:03:45) or leave blank: " END

    echo ""

    if [ -n "$START" ] && [ -n "$END" ]; then
        echo -e "🎬 ${CYAN}Downloading segment from $START to $END...${NC}"

        yt-dlp \
            --download-sections "*${START}-${END}" \
            -f bestvideo+bestaudio \
            --merge-output-format mp4 \
            -o "$OUTPUT_DIR/%(title)s_clip.%(ext)s" \
            "$URL"

    else
        echo -e "⬇️ ${CYAN}No valid timestamps provided. Downloading full video...${NC}"

        yt-dlp \
            -f bestvideo+bestaudio \
            --merge-output-format mp4 \
            -o "$OUTPUT_DIR/%(title)s.%(ext)s" \
            "$URL"
    fi

    echo -e "\n${GREEN}✅ Done!${NC}"
    pause
}

# --- MAIN MENU ---
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}VIDEO MASTER CONTROL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Standard Download (Auto)"
    echo "2) Best Quality Download (Video + Audio)"
    echo "3) Extract Audio Only (MP3)"
    echo "4) List Available Qualities / Formats"
    echo "5) Download Specific Video Segment (Clip)"
    echo -e "-----------------------------------"
    echo "X) Exit"
    echo ""

    read -p "Select Option: " choice
    case ${choice:-} in
        1) check_dependencies && download_standard ;;
        2) check_dependencies && download_best ;;
        3) check_dependencies && download_audio ;;
        4) check_dependencies && list_formats ;;
        5) check_dependencies && download_clip ;;
        [xX]) exit 0 ;;
        *) echo -e "${RED}Invalid option.${NC}" ; pause ;;
    esac
done

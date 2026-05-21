#!/bin/bash

# Zorg dat autocomplete het scherm niet overvol maakt door het te wissen bij tab
set -o emacs
bind '"\t": "\C-l\e\e"' 2>/dev/null || true

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

export PATH="$HOME/.local/bin:$PATH"

check_dependencies() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${YELLOW}'fzf' (Fuzzy Finder) is not installed.${NC}"
        read -e -p "Do you want to download and install 'fzf' locally? [Y/n]: " inst_choice
        if [[ "$inst_choice" == "n" || "$inst_choice" == "N" ]]; then
            echo -e "${RED}Exiting. Please install manually from https://github.com/junegunn/fzf/releases/latest${NC}"
            exit 1
        fi

        echo -e "${CYAN}Detecting system architecture...${NC}"
        local arch=$(uname -m)
        local asset=""

        case $arch in
            x86_64) asset="fzf-0.72.0-linux_amd64.tar.gz" ;;
            aarch64) asset="fzf-0.72.0-linux_arm64.tar.gz" ;;
            armv7l) asset="fzf-0.72.0-linux_armv7.tar.gz" ;;
            *)
                echo -e "${RED}Unsupported architecture ($arch) for automatic download.${NC}"
                echo -e "${YELLOW}Please install manually from https://github.com/junegunn/fzf/releases/latest${NC}"
                exit 1
                ;;
        esac

        # Download and install
        local dl_url="https://github.com/junegunn/fzf/releases/download/v0.72.0/$asset"
        echo -e "${CYAN}Downloading $asset...${NC}"

        mkdir -p /tmp/fzf_install
        if curl -sL "$dl_url" -o "/tmp/fzf_install/$asset"; then
            tar -xzf "/tmp/fzf_install/$asset" -C /tmp/fzf_install
            mkdir -p "$HOME/.local/bin"
            cp /tmp/fzf_install/fzf "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/fzf"
            echo -e "${GREEN}'fzf' installed successfully to $HOME/.local/bin/fzf${NC}"
        else
            echo -e "${RED}Download failed. Please check your internet connection or install manually.${NC}"
            exit 1
        fi
        rm -rf /tmp/fzf_install
    fi
}

get_target() {
    read -e -p "From which directory do you want to search? (Enter = current): " target_path
    target_path="${target_path:-.}"

    if [[ ! -d "$target_path" ]]; then
        echo -e "${RED}Directory does not exist!${NC}"
        return 1
    fi
    return 0
}

search_and_open() {
    if ! get_target; then return; fi
    echo -e "${CYAN}Use fzf to search for a file. Press ESC or CTRL-C to cancel.${NC}"

    # Use fzf to pick a file
    selected_file=$(find "$target_path" -type f 2>/dev/null | fzf --prompt="Search file> " --height=40% --layout=reverse --border)

    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        echo -e "\nYou selected: ${GREEN}$selected_file${NC}"

        editor="${EDITOR:-nano}"
        "$editor" "$selected_file"
    else
        echo -e "${YELLOW}No file selected.${NC}"
    fi
    pause
}

search_content() {
    if ! get_target; then return; fi
    read -p "Enter search term (for grep): " search_term

    if [[ -z "$search_term" ]]; then
         echo -e "${RED}No search term provided.${NC}"
         pause
         return
    fi

    echo -e "${CYAN}Searching file content via fzf...${NC}"
    # grep searches content and pipes to fzf, showing filename and line
    selected_match=$(grep -rnI "$search_term" "$target_path" 2>/dev/null | fzf --prompt="Select match> " --height=40% --layout=reverse --border)

    if [[ -n "$selected_match" ]]; then
        echo -e "\nYou selected:"
        echo -e "${GREEN}$selected_match${NC}"

        # Try to open the file in an editor
        file_to_open=$(echo "$selected_match" | cut -d: -f1)
        if [[ -f "$file_to_open" ]]; then
            read -p "Do you want to open this file in the editor? [Y/n]: " open_choice
            if [[ "$open_choice" != "n" && "$open_choice" != "N" ]]; then
                editor="${EDITOR:-nano}"
                "$editor" "$file_to_open"
            fi
        fi
    else
        echo -e "${YELLOW}No match selected or found.${NC}"
    fi
    pause
}

search_and_move() {
    if ! get_target; then return; fi
    echo -e "${CYAN}Use fzf to search for a source file.${NC}"

    selected_file=$(find "$target_path" -type f 2>/dev/null | fzf --prompt="Select file to move> " --height=40% --layout=reverse --border)

    if [[ -n "$selected_file" && -f "$selected_file" ]]; then
        echo -e "\nTo move: ${GREEN}$selected_file${NC}"
        read -e -p "Enter destination folder or new filename: " dest_path

        if [[ -n "$dest_path" ]]; then
            mv -v "$selected_file" "$dest_path"
            echo -e "${GREEN}File moved!${NC}"
        else
            echo -e "${RED}No destination provided.${NC}"
        fi
    else
        echo -e "${YELLOW}No file selected.${NC}"
    fi
    pause
}

check_dependencies

while true; do
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "         ${CYAN}FUZZY FINDER MANAGER (fzf)${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo "1) Search and open file"
    echo "2) Search file content (grep + fzf)"
    echo "3) Search and move file"
    echo "0) Back / Exit"
    echo -e "${CYAN}================================================${NC}"

    read -p "Choose an option: " choice
    case $choice in
        1) search_and_open ;;
        2) search_content ;;
        3) search_and_move ;;
        0) break ;;
        *) echo -e "${RED}Invalid choice.${NC}"; sleep 1 ;;
    esac
done
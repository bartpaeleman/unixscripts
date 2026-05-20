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

check_dependencies() {
    if ! command -v rename &> /dev/null; then
        echo -e "${RED}'rename' is not installed.${NC}"
        echo -e "${YELLOW}Please install it manually. Example for QNAP/Entware: 'opkg install rename', or Debian: 'apt-get install rename'.${NC}"
        pause
        exit 1
    fi
}

get_target() {
    read -e -p "Specify file or directory (use Tab for autocomplete): " target_path
    target_path="${target_path:-.}"

    if [[ ! -e "$target_path" ]]; then
        echo -e "${RED}File or directory does not exist!${NC}"
        return 1
    fi
    return 0
}

run_rename() {
    local expr="$1"

    read -p "Execute as Dry-run (do not rename anything yet)? [Y/n]: " dry_choice
    local flags="-v -d"
    if [[ "$dry_choice" != "n" && "$dry_choice" != "N" ]]; then
        flags="$flags -n"
        echo -e "${YELLOW}[DRY RUN MODE]${NC}"
    fi

    if [[ -d "$target_path" ]]; then
        read -p "Search in subfolders too (recursive)? [y/N]: " recurse
        if [[ "$recurse" == "y" || "$recurse" == "Y" ]]; then
            # Use find and pipe output to rename via xargs
            # -print0 and -0 for spaces in filenames
            echo -e "${CYAN}Executing on folder recursively...${NC}"
            find "$target_path" -type f -print0 | xargs -0 rename $flags "$expr"
        else
            echo -e "${CYAN}Executing on folder (only directly inside)...${NC}"
            # Prevent error if folder is empty
            shopt -s nullglob
            # rename expects files as arguments.
            rename $flags "$expr" "$target_path"/*
            shopt -u nullglob
        fi
    else
        echo -e "${CYAN}Executing on specific file...${NC}"
        rename $flags "$expr" "$target_path"
    fi
    pause
}

check_dependencies

if ! get_target; then
    exit 1
fi

while true; do
    clear
    echo -e "${CYAN}================================================${NC}"
    echo -e "         ${CYAN}ADVANCED RENAME (plasmasturm)${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "Target: ${YELLOW}$target_path${NC}\n"
    echo "1) Search and Replace (s/search/replace/g)"
    echo "2) All to lowercase (tr/A-Z/a-z/)"
    echo "3) All to UPPERCASE (tr/a-z/A-Z/)"
    echo "4) Remove specific text (s/string//g)"
    echo "5) Replace spaces with underscores (s/ /_/g)"
    echo "6) Add Prefix to the name"
    echo "7) Add Suffix (before extension)"
    echo "8) Custom Perl Expression"
    echo "0) Back / Exit"
    echo -e "${CYAN}================================================${NC}"

    read -p "Choose an option: " choice
    case $choice in
        1)
            read -p "Search text: " search_text
            read -p "Replace with: " replace_text
            # Basic escape for slashes to prevent breaking the expression
            s_escaped=$(echo "$search_text" | sed 's/\//\\\//g')
            r_escaped=$(echo "$replace_text" | sed 's/\//\\\//g')
            run_rename "s/$s_escaped/$r_escaped/g"
            ;;
        2)
            run_rename 'tr/A-Z/a-z/'
            ;;
        3)
            run_rename 'tr/a-z/A-Z/'
            ;;
        4)
            read -p "Text to remove: " rem_text
            r_escaped=$(echo "$rem_text" | sed 's/\//\\\//g')
            run_rename "s/$r_escaped//g"
            ;;
        5)
            run_rename 's/ /_/g'
            ;;
        6)
            read -p "Prefix text: " prefix_text
            p_escaped=$(echo "$prefix_text" | sed 's/\//\\\//g')
            # '$_' holds the filename. Prefix prepends it.
            run_rename "s/^/$p_escaped/"
            ;;
        7)
            read -p "Suffix text: " suffix_text
            s_escaped=$(echo "$suffix_text" | sed 's/\//\\\//g')
            # Insert right before the last dot (extension), or at the end if no dot
            run_rename "s/(\.[^.]+)?$/$s_escaped\$1/"
            ;;
        8)
            read -p "Provide full Perl expression (e.g. s/foo/bar/): " custom_expr
            run_rename "$custom_expr"
            ;;
        0) break ;;
        *) echo -e "${RED}Invalid choice.${NC}"; sleep 1 ;;
    esac
done
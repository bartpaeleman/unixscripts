#!/bin/bash

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Voeg lokaal bin pad toe voor de huidige sessie, zodat geinstalleerde binaries gevonden worden
export PATH="$HOME/.local/bin:$PATH"

check_dependencies() {
    local install_needed=false
    local rnr_bin=$(command -v rnr)

    if [[ -z "$rnr_bin" ]]; then
        install_needed=true
        echo -e "${YELLOW}'rnr' (Advanced Rename Tool) is not installed.${NC}"
    elif ! "$rnr_bin" --version &> /dev/null; then
        # Catch GLIBC linker errors from previously installed wrong binary versions
        install_needed=true
        echo -e "${RED}'rnr' is installed at $rnr_bin but cannot execute (likely GLIBC error). Replacing it...${NC}"
        if rm -f "$rnr_bin" 2>/dev/null; then
             echo -e "${YELLOW}Corrupted binary removed successfully.${NC}"
        else
             echo -e "${RED}Failed to remove $rnr_bin. Permission denied. Please delete it manually and re-run this script.${NC}"
             exit 1
        fi
    fi

    if [ "$install_needed" = true ]; then
        read -e -p "Do you want to download and install 'rnr' locally? [Y/n]: " inst_choice
        if [[ "$inst_choice" == "n" || "$inst_choice" == "N" ]]; then
            echo -e "${RED}Exiting. Please install manually from https://github.com/ismaelgv/rnr/releases/latest${NC}"
            exit 1
        fi

        echo -e "${CYAN}Detecting system architecture...${NC}"
        local arch=$(uname -m)
        local asset=""

        case $arch in
            x86_64) asset="rnr-v0.5.1-x86_64-unknown-linux-musl.tar.gz" ;;
            aarch64) asset="rnr-v0.5.1-aarch64-unknown-linux-gnu.tar.gz" ;;
            armv7l) asset="rnr-v0.5.1-armv7-unknown-linux-gnueabihf.tar.gz" ;;
            *)
                echo -e "${RED}Unsupported architecture ($arch) for automatic download.${NC}"
                echo -e "${YELLOW}Please install manually from https://github.com/ismaelgv/rnr/releases/latest${NC}"
                exit 1
                ;;
        esac

        # Download and install
        local dl_url="https://github.com/ismaelgv/rnr/releases/download/v0.5.1/$asset"
        echo -e "${CYAN}Downloading $asset...${NC}"

        mkdir -p /tmp/rnr_install
        if curl -sL "$dl_url" -o "/tmp/rnr_install/$asset"; then
            tar -xzf "/tmp/rnr_install/$asset" -C /tmp/rnr_install
            mkdir -p "$HOME/.local/bin"
            # Release contains a subfolder with the same name as the asset minus .tar.gz
            local folder_name="${asset%.tar.gz}"
            cp "/tmp/rnr_install/$folder_name/rnr" "$HOME/.local/bin/"
            chmod +x "$HOME/.local/bin/rnr"
            echo -e "${GREEN}'rnr' installed successfully to $HOME/.local/bin/rnr${NC}"
        else
            echo -e "${RED}Download failed. Please check your internet connection or install manually.${NC}"
            exit 1
        fi
        rm -rf /tmp/rnr_install
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
    local search_term="$1"
    local replace_term="$2"
    local extra_flags="${3:-}"

    read -e -p "Execute as Dry-run (do not rename anything yet)? [Y/n]: " dry_choice
    local rnr_command="rnr regex"

    if [[ "$dry_choice" == "n" || "$dry_choice" == "N" ]]; then
        rnr_command="$rnr_command -f"
    else
        echo -e "${YELLOW}[DRY RUN MODE]${NC}"
    fi

    # voeg de text transform flag toe als die meegeleverd is
    if [[ -n "$extra_flags" ]]; then
         rnr_command="$rnr_command $extra_flags"
    fi

    if [[ -d "$target_path" ]]; then
        read -e -p "Search in subfolders too (recursive)? [y/N]: " recurse
        if [[ "$recurse" == "y" || "$recurse" == "Y" ]]; then
            echo -e "${CYAN}Executing on folder recursively...${NC}"
            # Let rnr do the recursion (-r) and allow dir matching (-D) if needed, but normally we just rename files.
            # Using -r to recursive in rnr:
            eval $rnr_command -r -- \"\$search_term\" \"\$replace_term\" \"\$target_path\"
        else
            echo -e "${CYAN}Executing on folder (only directly inside)...${NC}"
            # Prevent error if folder is empty by executing via wildcard directly with bash expand
            shopt -s nullglob
            eval $rnr_command -- \"\$search_term\" \"\$replace_term\" \"\$target_path\"/*
            shopt -u nullglob
        fi
    else
        echo -e "${CYAN}Executing on specific file...${NC}"
        eval $rnr_command -- \"\$search_term\" \"\$replace_term\" \"\$target_path\"
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
    echo -e "         ${CYAN}ADVANCED RENAME${NC}"
    echo -e "${CYAN}================================================${NC}"
    echo -e "Target: ${YELLOW}$target_path${NC}\n"
    echo "1) Search and Replace (regex)"
    echo "2) All to lowercase"
    echo "3) All to UPPERCASE"
    echo "4) Remove specific text"
    echo "5) Replace spaces with underscores"
    echo "6) Add Prefix to the name"
    echo "7) Add Suffix (before extension)"
    echo "X) Back / Exit"
    echo -e "${CYAN}================================================${NC}"

    read -e -p "Choose an option: " choice
    case $choice in
        1)
            read -e -p "Search text (regex allowed): " search_text
            read -e -p "Replace with: " replace_text
            run_rename "$search_text" "$replace_text"
            ;;
        2)
            # Met rnr kan transformatie via -t lower en capture groepen '(.*)' en '${1}'
            run_rename '(.*)' '${1}' '-t lower'
            ;;
        3)
            run_rename '(.*)' '${1}' '-t upper'
            ;;
        4)
            read -e -p "Text to remove: " rem_text
            run_rename "$rem_text" ""
            ;;
        5)
            run_rename ' ' '_'
            ;;
        6)
            read -e -p "Prefix text: " prefix_text
            run_rename '^' "$prefix_text"
            ;;
        7)
            read -e -p "Suffix text: " suffix_text
            run_rename '(\.[^.]+)?$' "${suffix_text}\$1"
            ;;
        [Xx]) break ;;
        *) echo -e "${RED}Invalid choice.${NC}"; sleep 1 ;;
    esac
done
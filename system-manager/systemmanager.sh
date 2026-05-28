#!/bin/sh

# SYSTEM/systemmanager.sh v1.0.0
# Main control panel for QNAP/Linux system tools
# Compatible with BusyBox (QNAP QTS) and standard bash (Linux/macOS)

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SYSTEM_DIR="$(cd "$(dirname "$0")" && pwd)"

while true; do
    clear
    printf "${CYAN}================================================\n${NC}"
    printf "        ${CYAN}SYSTEM CONTROL PANEL${NC}\n"
    printf "${CYAN}================================================\n${NC}"
    printf "${GREEN}Available tools:${NC}\n"
    printf "1) Crontab Manager\n"
    printf "2) Profile Alias Editor\n"
    printf "\n${YELLOW}X) Exit${NC}\n"
    printf "${CYAN}================================================\n${NC}"

    printf "Select action: "
    read choice

    case "$choice" in
        1) sh "$SYSTEM_DIR/crontab_manager.sh" ;;
        2) sh "$SYSTEM_DIR/profile_alias_editor.sh" ;;
        [xX])
            printf "${GREEN}Exiting...${NC}\n"
            clear
            exit 0
            ;;
        *)
            printf "${RED}Invalid choice.${NC}\n"
            sleep 1
            ;;
    esac
done

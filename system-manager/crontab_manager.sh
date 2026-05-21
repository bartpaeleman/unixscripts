#!/bin/sh

# SYSTEM/crontab_manager.sh v1.0.0
# Manage crontab entries interactively
# Compatible with BusyBox (QNAP QTS) and standard bash (Linux/macOS)

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

pause() {
    printf "\n${YELLOW}Druk op Enter om door te gaan...${NC}\n"
    read dummy
}

while true; do
    clear
    printf "${CYAN}================================================\n${NC}"
    printf "           ${CYAN}CRONTAB MANAGER${NC}\n"
    printf "${CYAN}================================================\n${NC}"
    printf "1) Bekijk User Crontab (List)\n"
    printf "2) Bewerk User Crontab (Edit)\n"
    printf "3) Wis User Crontab (Clear)\n"
    printf "4) Bekijk System Crontab (/etc/crontab)\n"
    printf "5) Bewerk System Crontab (/etc/crontab)\n"
    printf "6) Wis System Crontab (/etc/crontab)\n"
    printf "0) Terug\n"
    printf "${CYAN}================================================\n${NC}"

    printf "Kies een optie: "
    read choice

    case "$choice" in
        1)
            printf "\n${YELLOW}Huidige User Crontab:${NC}\n"
            crontab -l 2>/dev/null || printf "${RED}Geen crontab gevonden voor de huidige gebruiker.${NC}\n"
            pause
            ;;
        2)
            printf "\n${YELLOW}Open crontab editor...${NC}\n"
            # BusyBox crontab -e werkt anders: gebruik EDITOR of vi als fallback
            EDITOR="${EDITOR:-vi}"
            TMP_CRON="/tmp/crontab_edit_$$"
            crontab -l 2>/dev/null > "$TMP_CRON"
            "$EDITOR" "$TMP_CRON"
            crontab "$TMP_CRON"
            rm -f "$TMP_CRON"
            printf "${GREEN}Crontab bijgewerkt.${NC}\n"
            pause
            ;;
        3)
            printf "\n${RED}Weet je zeker dat je alle user crontab entries wilt wissen? (y/N)${NC}\n"
            printf "Bevestiging: "
            read confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                crontab -r 2>/dev/null && printf "${GREEN}User Crontab succesvol gewist.${NC}\n" \
                    || printf "${RED}Kon crontab niet wissen (mogelijk leeg).${NC}\n"
            else
                printf "${YELLOW}Geannuleerd.${NC}\n"
            fi
            pause
            ;;
        4)
            printf "\n${YELLOW}Huidige System Crontab (/etc/crontab):${NC}\n"
            if [ -f /etc/crontab ]; then
                cat /etc/crontab
            else
                printf "${RED}Geen system crontab gevonden (/etc/crontab bestaat niet).${NC}\n"
            fi
            pause
            ;;
        5)
            printf "\n${YELLOW}Open system crontab editor (sudo/root vereist)...${NC}\n"
            EDITOR="${EDITOR:-vi}"
            if [ "$(id -u)" = "0" ]; then
                touch /etc/crontab
                "$EDITOR" /etc/crontab
            else
                sudo touch /etc/crontab 2>/dev/null && sudo "$EDITOR" /etc/crontab \
                    || printf "${RED}Root-toegang vereist. Start het script als root of via sudo.${NC}\n"
            fi
            pause
            ;;
        6)
            printf "\n${RED}Weet je zeker dat je de system crontab (/etc/crontab) wilt wissen? (y/N)${NC}\n"
            printf "Bevestiging: "
            read confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                if [ "$(id -u)" = "0" ]; then
                    : > /etc/crontab
                    printf "${GREEN}System Crontab succesvol leeggemaakt.${NC}\n"
                else
                    sudo sh -c ': > /etc/crontab' 2>/dev/null \
                        && printf "${GREEN}System Crontab succesvol leeggemaakt.${NC}\n" \
                        || printf "${RED}Root-toegang vereist.${NC}\n"
                fi
            else
                printf "${YELLOW}Geannuleerd.${NC}\n"
            fi
            pause
            ;;
        0) break ;;
        *)
            printf "${RED}Ongeldige keuze.${NC}\n"
            sleep 1
            ;;
    esac
done

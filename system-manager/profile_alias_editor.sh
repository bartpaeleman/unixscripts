#!/bin/sh

# SYSTEM/profile_alias_editor.sh v1.0.0
# Bewerk en beheer persistente aliases op QNAP QTS en Linux.
#
# HOE PERSISTENTIE WERKT OP QNAP:
#   - /etc/profile wordt bij elke reboot overschreven door QTS (RAMDisk)
#   - Aliases worden persistent opgeslagen in ALIAS_STORE (op RAID-opslag)
#   - Bij elke reboot injecteert autorun.sh dit bestand terug in /etc/profile
#   - Zie optie 5 om autorun.sh automatisch in te stellen
#
# Compatible met BusyBox (QNAP QTS) en standaard bash (Linux/macOS)

GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Persistent opslaglocatie voor aliases (op RAID — overleeft reboots)
if [ -d "/share/Public" ]; then
    ALIAS_STORE="/share/Public/.bash_aliases"
else
    ALIAS_STORE="/share/CACHEDEV1_DATA/.bash_aliases"
fi

# Live profiel waar aliases actief worden geladen
LIVE_PROFILE="/etc/profile"

# autorun.sh locatie (QNAP Intel/AMD x86 — TS-464 valt hieronder)
AUTORUN="/tmp/config/autorun.sh"

pause() {
    printf "\n${YELLOW}Druk op Enter om door te gaan...${NC}\n"
    read dummy
}

# Zorg dat het alias-bestand bestaat
ensure_alias_store() {
    if [ ! -f "$ALIAS_STORE" ]; then
        printf "# Persistente aliases — beheerd door profile_alias_editor.sh\n" > "$ALIAS_STORE"
    fi
}

# Laad aliases live in het actieve profiel (vereist root)
inject_to_profile() {
    local marker="# >>> SYSTEM aliases begin <<<"
    local marker_end="# <<< SYSTEM aliases end >>>"

    if grep -q "$marker" "$LIVE_PROFILE" 2>/dev/null; then
        # Verwijder het oude blok (BusyBox-compatibele methode)
        awk "/$marker/{found=1} !found{print} /$marker_end/{found=0}" \
            "$LIVE_PROFILE" > /tmp/profile_clean_$$ && mv /tmp/profile_clean_$$ "$LIVE_PROFILE"
    fi

    # Voeg nieuw blok toe aan het einde
    printf "\n%s\n" "$marker" >> "$LIVE_PROFILE"
    printf "[ -f \"%s\" ] && . \"%s\"\n" "$ALIAS_STORE" "$ALIAS_STORE" >> "$LIVE_PROFILE"
    printf "%s\n" "$marker_end" >> "$LIVE_PROFILE"
}

# Controleer of autorun.sh al de alias-injectie bevat
autorun_has_injection() {
    grep -q "SYSTEM aliases" "$AUTORUN" 2>/dev/null
}

while true; do
    clear
    printf "${CYAN}================================================\n${NC}"
    printf "         ${CYAN}PROFILE ALIAS EDITOR${NC}\n"
    printf "${CYAN}================================================\n${NC}"
    printf "${YELLOW}Alias-bestand:${NC} %s\n" "$ALIAS_STORE"
    printf "${YELLOW}Live profiel  :${NC} %s\n" "$LIVE_PROFILE"
    printf "${CYAN}------------------------------------------------\n${NC}"
    printf "1) Bekijk huidige aliases\n"
    printf "2) Bewerk aliases (editor)\n"
    printf "3) Voeg alias toe (snel)\n"
    printf "4) Verwijder alias\n"
    printf "5) Activeer aliases nu (injecteer in /etc/profile)\n"
    printf "6) Bekijk /etc/profile\n"
    printf "7) Bewerk /etc/profile (editor)\n"
    printf "8) Stel autorun.sh in voor persistentie na reboot\n"
    printf "X) Terug\n"
    printf "${CYAN}================================================\n${NC}"

    printf "Kies een optie: "
    read choice

    case "$choice" in
        1)
            ensure_alias_store
            printf "\n${YELLOW}Huidige aliases in %s:${NC}\n" "$ALIAS_STORE"
            printf "${CYAN}------------------------------------------------\n${NC}"
            grep "^alias" "$ALIAS_STORE" 2>/dev/null \
                || printf "${YELLOW}Nog geen aliases gedefinieerd.${NC}\n"
            printf "${CYAN}------------------------------------------------\n${NC}"
            pause
            ;;
        2)
            ensure_alias_store
            EDITOR="${EDITOR:-vi}"
            "$EDITOR" "$ALIAS_STORE"
            printf "\n${GREEN}Opgeslagen in %s${NC}\n" "$ALIAS_STORE"
            printf "${YELLOW}Tip: kies optie 5 om de aliases nu te activeren.${NC}\n"
            pause
            ;;
        3)
            ensure_alias_store
            printf "\n${YELLOW}Alias toevoegen${NC}\n"
            printf "Naam  (bv. ll): "
            read alias_name
            if [ -z "$alias_name" ]; then
                printf "${RED}Geen naam opgegeven.${NC}\n"
                pause
                continue
            fi
            printf "Commando (bv. ls -la): "
            read alias_cmd
            if [ -z "$alias_cmd" ]; then
                printf "${RED}Geen commando opgegeven.${NC}\n"
                pause
                continue
            fi
            printf "alias %s='%s'\n" "$alias_name" "$alias_cmd" >> "$ALIAS_STORE"
            printf "${GREEN}Alias '%s' toegevoegd.${NC}\n" "$alias_name"
            printf "${YELLOW}Tip: kies optie 5 om de aliases nu te activeren.${NC}\n"
            pause
            ;;
        4)
            ensure_alias_store
            printf "\n${YELLOW}Huidige aliases:${NC}\n"
            grep -n "^alias" "$ALIAS_STORE" 2>/dev/null \
                || printf "${YELLOW}Geen aliases gevonden.${NC}\n"
            printf "\nNaam van de alias om te verwijderen: "
            read del_name
            if [ -z "$del_name" ]; then
                printf "${YELLOW}Geannuleerd.${NC}\n"
                pause
                continue
            fi
            if grep -q "^alias ${del_name}=" "$ALIAS_STORE" 2>/dev/null; then
                grep -v "^alias ${del_name}=" "$ALIAS_STORE" > /tmp/aliases_clean_$$ \
                    && mv /tmp/aliases_clean_$$ "$ALIAS_STORE"
                printf "${GREEN}Alias '%s' verwijderd.${NC}\n" "$del_name"
                printf "${YELLOW}Tip: kies optie 5 om de wijzigingen te activeren.${NC}\n"
            else
                printf "${RED}Alias '%s' niet gevonden.${NC}\n" "$del_name"
            fi
            pause
            ;;
        5)
            ensure_alias_store
            printf "\n${YELLOW}Aliases injecteren in %s...${NC}\n" "$LIVE_PROFILE"
            if [ "$(id -u)" = "0" ]; then
                inject_to_profile
                printf "${GREEN}Klaar. Aliases zijn actief in nieuwe shell-sessies.${NC}\n"
                printf "${YELLOW}Voor de huidige sessie: ${NC}. %s\n" "$LIVE_PROFILE"
                # Probeer het commando in de bash history van de gebruiker te zetten
                if [ -f "$HOME/.bash_history" ]; then
                    printf ". %s\n" "$LIVE_PROFILE" >> "$HOME/.bash_history"
                    printf "${CYAN}(Het commando is toegevoegd aan je geschiedenis. Druk na afsluiten op 'Pijltje Omhoog' en Enter!)${NC}\n"
                fi
            else
                printf "${RED}Root-toegang vereist voor schrijven naar %s.${NC}\n" "$LIVE_PROFILE"
                printf "${YELLOW}Start het script als root of voer uit via: sudo sh systemmanager.sh${NC}\n"
            fi
            pause
            ;;
        6)
            printf "\n${YELLOW}Inhoud van %s:${NC}\n" "$LIVE_PROFILE"
            printf "${CYAN}------------------------------------------------\n${NC}"
            if command -v more >/dev/null 2>&1; then
                cat "$LIVE_PROFILE" | more
            else
                cat "$LIVE_PROFILE"
            fi
            printf "${CYAN}------------------------------------------------\n${NC}"
            pause
            ;;
        7)
            if [ "$(id -u)" = "0" ]; then
                EDITOR="${EDITOR:-vi}"
                "$EDITOR" "$LIVE_PROFILE"
                printf "\n${GREEN}Opgeslagen in %s${NC}\n" "$LIVE_PROFILE"
            else
                printf "${RED}Root-toegang vereist voor bewerken van %s.${NC}\n" "$LIVE_PROFILE"
            fi
            pause
            ;;
        8)
            printf "\n${YELLOW}autorun.sh instellen voor persistentie na reboot...${NC}\n"
            if [ "$(id -u)" != "0" ]; then
                printf "${RED}Root-toegang vereist.${NC}\n"
                pause
                continue
            fi

            # Mount de config-partitie
            printf "Config-partitie mounten...\n"
            mkdir -p /tmp/config
            MOUNTED=0

            # Methode 1: HAL app (Recente QNAP's)
            BOOT_PD=$(/sbin/hal_app --get_boot_pd port_id=0 2>/dev/null)
            if [ -n "$BOOT_PD" ]; then
                if mount -t ext2 "${BOOT_PD}6" /tmp/config 2>/dev/null || mount -t ext4 "${BOOT_PD}6" /tmp/config 2>/dev/null || mount "${BOOT_PD}6" /tmp/config 2>/dev/null; then
                    MOUNTED=1
                fi
            fi

            # Methode 2: Fallback standaard mount points
            if [ "$MOUNTED" -eq 0 ]; then
                for dev in /dev/sdx6 /dev/mmcblk0p6; do
                    if mount -t ext2 "$dev" /tmp/config 2>/dev/null || mount -t ext4 "$dev" /tmp/config 2>/dev/null || mount "$dev" /tmp/config 2>/dev/null; then
                        MOUNTED=1
                        break
                    fi
                done
            fi

            # Controle of het mounten via /proc/mounts echt gelukt is (of al was)
            if grep -q "/tmp/config" /proc/mounts; then
                MOUNTED=1
            fi

            if [ "$MOUNTED" -eq 0 ]; then
                printf "${RED}Kon boot device partitie niet mounten.${NC}\n"
                printf "${YELLOW}Dit kan betekenen dat uw model een afwijkende flash-structuur heeft.\nMount /tmp/config handmatig en voer het script opnieuw uit.${NC}\n"
                pause
                continue
            fi

            if autorun_has_injection; then
                printf "${YELLOW}autorun.sh bevat al de alias-injectie.${NC}\n"
            else
                # Maak autorun.sh aan of voeg toe
                touch "$AUTORUN"
                chmod +x "$AUTORUN"

                # Voeg shebang toe als het bestand leeg is
                if [ ! -s "$AUTORUN" ]; then
                    printf "#!/bin/sh\n" > "$AUTORUN"
                fi

                cat >> "$AUTORUN" << AUTORUN_BLOCK

# >>> SYSTEM aliases begin <<<
# Injecteer persistente aliases in /etc/profile bij elke opstart
_ALIAS_STORE="${ALIAS_STORE}"
_MARKER_BEGIN="# >>> SYSTEM aliases begin <<<"
_MARKER_END="# <<< SYSTEM aliases end >>>"
if [ -f "\$_ALIAS_STORE" ]; then
    if grep -q "\$_MARKER_BEGIN" /etc/profile 2>/dev/null; then
        awk "/\$_MARKER_BEGIN/{found=1} !found{print} /\$_MARKER_END/{found=0}" \
            /etc/profile > /tmp/profile_clean && mv /tmp/profile_clean /etc/profile
    fi
    printf "\n%s\n" "\$_MARKER_BEGIN" >> /etc/profile
    printf "[ -f \"%s\" ] && . \"%s\"\n" "\$_ALIAS_STORE" "\$_ALIAS_STORE" >> /etc/profile
    printf "%s\n" "\$_MARKER_END" >> /etc/profile
fi
# <<< SYSTEM aliases end >>>
AUTORUN_BLOCK

                printf "${GREEN}Injectie-blok toegevoegd aan autorun.sh.${NC}\n"
            fi

            # Unmount
            umount /tmp/config 2>/dev/null
            printf "${GREEN}autorun.sh ingesteld. Aliases laden voortaan automatisch na elke reboot.${NC}\n"
            printf "${YELLOW}Vergeet niet: Control Panel → Hardware → General → Run user defined startup processes (autorun.sh) moet aangevinkt zijn!${NC}\n"
            pause
            ;;
        [Xx]) break ;;
        *)
            printf "${RED}Ongeldige keuze.${NC}\n"
            sleep 1
            ;;
    esac
done

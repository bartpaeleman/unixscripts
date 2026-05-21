#!/bin/bash

# ============================================================
# DATABASE MASTER TOOL
# Menu for Backup and Analysis
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to get credentials
get_creds() {
    read -e -p "Database Name: " DB_NAME
    read -e -p "Database User [root]: " DB_USER
    DB_USER=${DB_USER:-root}
    read -rsp "Database Password: " DB_PASS
    echo ""

    # Auto-detect default host or socket
    DEFAULT_HOST="127.0.0.1"

    # QNAP specific checks
    if command -v getcfg &> /dev/null; then
        # Try to find the active socket file
        if [ -S "/var/run/mariadb10.sock" ]; then
            DEFAULT_HOST="/var/run/mariadb10.sock"
        elif [ -S "/tmp/mariadb10.sock" ]; then
            DEFAULT_HOST="/tmp/mariadb10.sock"
        elif [ -S "/tmp/mysql.sock" ]; then
            DEFAULT_HOST="/tmp/mysql.sock"
        fi
    fi

    echo -e "${CYAN}Tip: Press Enter to use the detected default for Host/Socket.${NC}"
    read -e -p "Host/Socket [$DEFAULT_HOST]: " DB_HOST
    DB_HOST=${DB_HOST:-$DEFAULT_HOST}
}

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

backup_db() {
    echo -e "\n${CYAN}=== Database Backup ===${NC}"
    get_creds

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"

    echo -e "\nBacking up '$DB_NAME'..."

    # Use existing backup script logic but inline here for simpler menu or call it?
    # Calling the existing logic inline is safer to keep it contained.

    TMP_CNF=$(mktemp)
    chmod 600 "$TMP_CNF"
    echo "[client]" > "$TMP_CNF"
    echo "user=$DB_USER" >> "$TMP_CNF"
    echo "password=$DB_PASS" >> "$TMP_CNF"

    if [[ "$DB_HOST" == /* ]]; then
        echo "socket=$DB_HOST" >> "$TMP_CNF"
    else
        echo "host=$DB_HOST" >> "$TMP_CNF"
    fi

    # Detect QNAP specialized path if no global command is found
    DUMP_CMD=""
    if command -v mariadb-dump &> /dev/null; then
        DUMP_CMD="mariadb-dump"
    elif command -v mysqldump &> /dev/null; then
        DUMP_CMD="mysqldump"
    elif command -v getcfg &> /dev/null; then
        QNAP_MARIADB_PATH=$(getcfg MariaDB10 Install_Path -f /etc/config/qpkg.conf 2>/dev/null)
        if [[ -n "$QNAP_MARIADB_PATH" && -x "$QNAP_MARIADB_PATH/bin/mysqldump" ]]; then
            DUMP_CMD="$QNAP_MARIADB_PATH/bin/mysqldump"
        fi
    fi

    if [[ -z "$DUMP_CMD" ]]; then
        echo -e "${RED}✗ Error: Neither mysqldump nor mariadb-dump found.${NC}"
        rm -f "$TMP_CNF"
        pause
        return
    fi

    # Use set +e locally to catch error without exiting script
    set +e
    set -o pipefail

    "$DUMP_CMD" --defaults-extra-file="$TMP_CNF" "$DB_NAME" | gzip > "$FILENAME"

    STATUS=$?
    set +o pipefail
    set -e

    if [ $STATUS -eq 0 ]; then
        echo -e "${GREEN}✓ Backup successful!${NC}"
        echo -e "  File: $(pwd)/$FILENAME"
        echo -e "  Size: $(du -h "$FILENAME" | cut -f1)"
    else
        echo -e "${RED}✗ Backup failed.${NC}"
        rm -f "$FILENAME"
    fi
    rm -f "$TMP_CNF"
    pause
}

analyze_db() {
    echo -e "\n${CYAN}=== Database Analysis ===${NC}"
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python3 is required for analysis.${NC}"
        pause
        return
    fi

    get_creds

    echo -e "\nFetching statistics..."
    export DB_PASS
    python3 "$SCRIPT_DIR/db_stats.py" "$DB_HOST" "$DB_USER" "$DB_NAME"
    unset DB_PASS
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}DATABASE MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"
    echo "1) Backup Database"
    echo "2) Analyze Database (Table Stats)"
    echo "X) Exit"

    read -e -p "Select: " choice
    case $choice in
        1) backup_db ;;
        2) analyze_db ;;
        [Xx]) exit 0 ;;
    esac
done

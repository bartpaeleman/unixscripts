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

# Global State
DB_CONNECTED=false
GLOBAL_DB_USER="root"
GLOBAL_DB_PASS=""
GLOBAL_DB_HOST="127.0.0.1"
MYSQL_CMD=""
MYSQLDUMP_CMD=""

# Function to detect binaries
detect_binaries() {
    if command -v mariadb &> /dev/null; then
        MYSQL_CMD="mariadb"
    elif command -v mysql &> /dev/null; then
        MYSQL_CMD="mysql"
    elif command -v getcfg &> /dev/null; then
        QNAP_MARIADB_PATH=$(getcfg MariaDB10 Install_Path -f /etc/config/qpkg.conf 2>/dev/null)
        if [[ -n "$QNAP_MARIADB_PATH" && -x "$QNAP_MARIADB_PATH/bin/mysql" ]]; then
            MYSQL_CMD="$QNAP_MARIADB_PATH/bin/mysql"
        fi
    fi

    if command -v mariadb-dump &> /dev/null; then
        MYSQLDUMP_CMD="mariadb-dump"
    elif command -v mysqldump &> /dev/null; then
        MYSQLDUMP_CMD="mysqldump"
    elif command -v getcfg &> /dev/null; then
        QNAP_MARIADB_PATH=$(getcfg MariaDB10 Install_Path -f /etc/config/qpkg.conf 2>/dev/null)
        if [[ -n "$QNAP_MARIADB_PATH" && -x "$QNAP_MARIADB_PATH/bin/mysqldump" ]]; then
            MYSQLDUMP_CMD="$QNAP_MARIADB_PATH/bin/mysqldump"
        fi
    fi
}

# Function to connect to server
connect_server() {
    echo -e "\n${CYAN}=== Connect to Server ===${NC}"
    detect_binaries

    if [[ -z "$MYSQL_CMD" ]]; then
        echo -e "${RED}✗ Error: Neither mysql nor mariadb client found.${NC}"
        pause
        return 1
    fi

    read -e -p "Database User [$GLOBAL_DB_USER]: " input_user
    GLOBAL_DB_USER=${input_user:-$GLOBAL_DB_USER}

    read -rsp "Database Password: " GLOBAL_DB_PASS
    echo ""

    # Auto-detect default host or socket
    local default_host="127.0.0.1"
    if command -v getcfg &> /dev/null; then
        if [ -S "/var/run/mariadb10.sock" ]; then
            default_host="/var/run/mariadb10.sock"
        elif [ -S "/tmp/mariadb10.sock" ]; then
            default_host="/tmp/mariadb10.sock"
        elif [ -S "/tmp/mysql.sock" ]; then
            default_host="/tmp/mysql.sock"
        fi
    fi

    echo -e "${CYAN}Tip: Press Enter to use the detected default for Host/Socket.${NC}"
    read -e -p "Host/Socket [$default_host]: " input_host
    GLOBAL_DB_HOST=${input_host:-$default_host}

    # Build connection args
    local conn_args=("-u" "$GLOBAL_DB_USER")
    if [[ "$GLOBAL_DB_HOST" == /* ]]; then
        conn_args+=("--socket=$GLOBAL_DB_HOST")
    else
        conn_args+=("-h" "$GLOBAL_DB_HOST")
    fi

    echo "Testing connection..."
    export MYSQL_PWD="$GLOBAL_DB_PASS"
    set +e
    "$MYSQL_CMD" "${conn_args[@]}" -e "SELECT 1;" > /dev/null 2>&1
    local status=$?
    set -e

    if [ $status -eq 0 ]; then
        echo -e "${GREEN}✓ Connection established successfully.${NC}"
        DB_CONNECTED=true
    else
        echo -e "${RED}✗ Connection failed. Check credentials and host.${NC}"
        DB_CONNECTED=false
        GLOBAL_DB_PASS="" # clear failed password
    fi
    pause
}

pause() {
    echo -e "\n${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to get database name with autocomplete
get_db_name() {
    local conn_args=("-u" "$GLOBAL_DB_USER")
    if [[ "$GLOBAL_DB_HOST" == /* ]]; then
        conn_args+=("--socket=$GLOBAL_DB_HOST")
    else
        conn_args+=("-h" "$GLOBAL_DB_HOST")
    fi

    # Fetch databases
    export MYSQL_PWD="$GLOBAL_DB_PASS"
    local dbs=$("$MYSQL_CMD" "${conn_args[@]}" -sNe "SHOW DATABASES;" 2>/dev/null)

    if [[ -z "$dbs" ]]; then
        # Fallback if no DBs retrieved
        read -e -p "Database Name: " DB_NAME
        return
    fi

    # Create temporary directory for bash completion trick
    local tmp_dir=$(mktemp -d)
    for db in $dbs; do
        touch "$tmp_dir/$db"
    done

    # Use a subshell to change directory safely
    DB_NAME=$(
        cd "$tmp_dir"
        read -e -p "Database Name (TAB to autocomplete): " input_db > /dev/tty < /dev/tty
        echo "$input_db"
    )

    rm -rf "$tmp_dir"
}

backup_db() {
    echo -e "\n${CYAN}=== Database Backup ===${NC}"

    if [ "$DB_CONNECTED" != true ]; then
        connect_server || return
    fi

    get_db_name
    if [[ -z "$DB_NAME" ]]; then
        echo -e "${RED}✗ Action cancelled.${NC}"
        pause
        return
    fi

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"

    echo -e "\nBacking up '$DB_NAME'..."

    TMP_CNF=$(mktemp)
    chmod 600 "$TMP_CNF"
    echo "[client]" > "$TMP_CNF"
    echo "user=$GLOBAL_DB_USER" >> "$TMP_CNF"
    echo "password=$GLOBAL_DB_PASS" >> "$TMP_CNF"

    if [[ "$GLOBAL_DB_HOST" == /* ]]; then
        echo "socket=$GLOBAL_DB_HOST" >> "$TMP_CNF"
    else
        echo "host=$GLOBAL_DB_HOST" >> "$TMP_CNF"
    fi

    if [[ -z "$MYSQLDUMP_CMD" ]]; then
        echo -e "${RED}✗ Error: Neither mysqldump nor mariadb-dump found.${NC}"
        rm -f "$TMP_CNF"
        pause
        return
    fi

    # Use set +e locally to catch error without exiting script
    set +e
    set -o pipefail

    "$MYSQLDUMP_CMD" --defaults-extra-file="$TMP_CNF" "$DB_NAME" | gzip > "$FILENAME"

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

    if [ "$DB_CONNECTED" != true ]; then
        connect_server || return
    fi

    get_db_name
    if [[ -z "$DB_NAME" ]]; then
        echo -e "${RED}✗ Action cancelled.${NC}"
        pause
        return
    fi

    echo -e "\nFetching statistics..."
    export DB_PASS="$GLOBAL_DB_PASS"
    python3 "$SCRIPT_DIR/db_stats.py" "$GLOBAL_DB_HOST" "$GLOBAL_DB_USER" "$DB_NAME"
    unset DB_PASS
    pause
}

# MAIN MENU
while true; do
    clear
    echo -e "${CYAN}===================================${NC}"
    echo -e "      ${CYAN}DATABASE MASTER TOOL${NC}"
    echo -e "${CYAN}===================================${NC}"

    if [ "$DB_CONNECTED" = true ]; then
        echo -e "Status: ${GREEN}Connected${NC} ($GLOBAL_DB_USER @ $GLOBAL_DB_HOST)"
    else
        echo -e "Status: ${RED}Disconnected${NC}"
    fi
    echo -e "-----------------------------------"
    echo "C) Connect to Server"
    echo "1) Backup Database"
    echo "2) Analyze Database (Table Stats)"
    echo "X) Exit"

    read -e -p "Select: " choice
    case $choice in
        [Cc]) connect_server ;;
        1) backup_db ;;
        2) analyze_db ;;
        [Xx]) exit 0 ;;
    esac
done

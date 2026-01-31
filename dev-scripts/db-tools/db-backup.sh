#!/bin/bash

# ============================================================
# DATABASE BACKUP TOOL
# Quick MySQL/MariaDB backup wrapper for QNAP & macOS
# ============================================================

set -e
set -o pipefail

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
NC='\033[0m'

# Check if mysqldump is installed
if ! command -v mysqldump &> /dev/null; then
    echo -e "${RED}Error: mysqldump command not found.${NC}"
    echo "Please ensure MySQL/MariaDB client tools are installed and in your PATH."
    # On QNAP, path might be special, e.g., /usr/local/mysql/bin
    if [[ -f "/usr/local/mysql/bin/mysqldump" ]]; then
        echo "Found at /usr/local/mysql/bin/mysqldump. Updating PATH."
        export PATH=$PATH:/usr/local/mysql/bin
    else
        exit 1
    fi
fi

echo -e "${CYAN}=== Database Backup Tool ===${NC}"

# 1. Configuration
read -p "Database Name: " DB_NAME
read -p "Database User [root]: " DB_USER
DB_USER=${DB_USER:-root}
read -rsp "Database Password: " DB_PASS
echo ""
read -p "Host [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILENAME="${DB_NAME}_${TIMESTAMP}.sql.gz"

# 2. Execute Backup
echo -e "\n${CYAN}Backing up '$DB_NAME' to '$FILENAME'...${NC}"

# Using temporary credentials file to avoid warning on CLI
TMP_CNF=$(mktemp)
chmod 600 "$TMP_CNF"
echo "[client]" > "$TMP_CNF"
echo "user=$DB_USER" >> "$TMP_CNF"
echo "password=$DB_PASS" >> "$TMP_CNF"
echo "host=$DB_HOST" >> "$TMP_CNF"

if mysqldump --defaults-extra-file="$TMP_CNF" "$DB_NAME" | gzip > "$FILENAME"; then
    echo -e "${GREEN}✓ Backup successful!${NC}"
    echo -e "  File: $(pwd)/$FILENAME"
    echo -e "  Size: $(du -h "$FILENAME" | cut -f1)"
else
    echo -e "${RED}✗ Backup failed.${NC}"
    rm -f "$FILENAME"
fi

# Cleanup
rm -f "$TMP_CNF"

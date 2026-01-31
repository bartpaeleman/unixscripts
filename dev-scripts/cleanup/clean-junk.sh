#!/bin/bash

# ============================================================
# PROJECT CLEANUP TOOL
# Removes system junk files (.DS_Store, Thumbs.db, etc)
# ============================================================

set -e

# Colors
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_DIR="${1:-.}"

echo -e "${CYAN}=== Project Cleanup Tool ===${NC}"
echo -e "Target: $TARGET_DIR"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: Directory not found."
    exit 1
fi

echo -e "\nScanning for junk files..."

# Count files to be deleted
COUNT_DS=$(find "$TARGET_DIR" -name ".DS_Store" | wc -l)
COUNT_THUMBS=$(find "$TARGET_DIR" -name "Thumbs.db" | wc -l)
COUNT_U=$(find "$TARGET_DIR" -name "._*" | wc -l)
TOTAL=$((COUNT_DS + COUNT_THUMBS + COUNT_U))

if [[ $TOTAL -eq 0 ]]; then
    echo -e "${GREEN}No junk files found. Directory is clean.${NC}"
    exit 0
fi

echo -e "${YELLOW}Found:$NC"
echo "  .DS_Store: $COUNT_DS"
echo "  Thumbs.db: $COUNT_THUMBS"
echo "  ._* files: $COUNT_U"

read -p "Delete these $TOTAL files? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" ]]; then
    find "$TARGET_DIR" -name ".DS_Store" -delete
    find "$TARGET_DIR" -name "Thumbs.db" -delete
    find "$TARGET_DIR" -name "._*" -delete
    echo -e "${GREEN}✓ Cleanup complete.${NC}"
else
    echo "Operation cancelled."
fi

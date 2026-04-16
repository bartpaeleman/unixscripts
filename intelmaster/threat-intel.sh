#!/usr/bin/env bash
# threat-intel.sh
# Aggregates Threat Intelligence from various sources, parses them,
# and generates a matching report via an embedded Python analyzer.

set -euo pipefail

# Define paths
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/config.json"
SRC_DIR="$SCRIPT_DIR/src"
ASSETS_DIR="$SCRIPT_DIR/assets"
PUBLIC_DIR="$SCRIPT_DIR/public"
ANALYZER_SCRIPT="$SRC_DIR/analyzer.py"
CSS_FILE="$ASSETS_DIR/style.css"

# Temporary directory for raw downloads
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Ensure public directory exists
mkdir -p "$PUBLIC_DIR"

# Ensure secure permissions on config if it exists
if [ -f "$CONFIG_FILE" ]; then
    chmod 600 "$CONFIG_FILE"
else
    echo "Error: config.json not found in $SCRIPT_DIR" >&2
    exit 1
fi

# Function to extract JSON array elements using Python (avoids missing jq dependency)
get_sources() {
    python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
        for i, src in enumerate(data.get('sources', [])):
            print(f\"{i}|{src.get('url', '')}\")
except Exception as e:
    sys.exit(1)
"
}

echo "[*] Threat Intel Aggregator Started: $(date)"

# Fetch data
echo "[*] Fetching threat intelligence sources..."
while IFS='|' read -r index url; do
    if [ -z "$url" ]; then
        continue
    fi

    echo "    -> Downloading from: $url"

    # Secure download with curl
    # -s: silent
    # -L: follow redirects
    # -A: set realistic User-Agent to prevent 403 blocks
    # -m: max time 30s
    raw_file="$TMP_DIR/source_${index}.raw"
    if ! curl -s -L -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36" \
         -m 30 "$url" -o "$raw_file"; then
        echo "    [!] Warning: Failed to download $url" >&2
    fi
done < <(get_sources)

# Run Python Analyzer
echo "[*] Analyzing data and generating report..."
if [ -f "$ANALYZER_SCRIPT" ]; then
    REPORT_PATH=$(python3 "$ANALYZER_SCRIPT" "$CONFIG_FILE" "$TMP_DIR" "$PUBLIC_DIR" "$CSS_FILE")

    if [ -n "$REPORT_PATH" ] && [ -f "$REPORT_PATH" ]; then
        echo "[+] Report successfully generated: $REPORT_PATH"
        # Set proper permissions for the output directory/files
        chmod 755 "$PUBLIC_DIR"
        chmod 644 "$REPORT_PATH"
    else
        echo "[-] Failed to generate report." >&2
        exit 1
    fi
else
    echo "[-] Error: Analyzer script not found at $ANALYZER_SCRIPT" >&2
    exit 1
fi

echo "[*] Done."
exit 0

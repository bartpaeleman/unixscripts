#!/bin/bash
# Wrapper script to run python scripts ensuring dependencies are met

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
REQUIREMENTS="$BASE_DIR/requirements.txt"

# Check if requirements.txt exists and update/install dependencies
if [ -f "$REQUIREMENTS" ]; then
    # Print to stderr so we don't break stdout JSON pipelines
    echo "[info] Checking dependencies from $REQUIREMENTS..." >&2
    python3 -m pip install -r "$REQUIREMENTS" -q >&2
fi

# Run the passed python script and arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <python_script> [args...]"
else
    python3 "$@"
fi

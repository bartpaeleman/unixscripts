# Cleanup Master Tool

A unified utility for maintaining clean file systems on development machines.

## Usage

```bash
./cleanup-master.sh
```

## Features

### 1. System Junk Cleaner
Recursively removes operating system metadata files that clutter repositories.
- **Targets**: `.DS_Store` (macOS), `Thumbs.db` (Windows), `._*` (AppleDouble files).
- **Safety**: Counts files and asks for confirmation before deletion.

### 2. Duplicate Finder
Uses Python to identify duplicate files based on content (MD5 hash), not just name.
- **Script**: `dedupe.py`
- **Output**: Lists original and duplicate file paths.
- **Safety**: Read-only mode (does not delete duplicates automatically).

## Requirements

- Bash Shell
- Python 3 (for duplicate finder)

# Project Cleanup Tool

A utility script to recursively remove operating system metadata files and other "junk" that often accidentally ends up in repositories or web server directories.

## Usage

```bash
# Clean current directory
./clean-junk.sh

# Clean specific directory
./clean-junk.sh /path/to/project
```

## What it cleans

- **.DS_Store**: macOS Folder settings
- **Thumbs.db**: Windows Thumbnail cache
- **._***: macOS Resource forks (common on non-HFS drives like QNAP SMB shares)

## Features

- **Safe**: Scans and reports what it finds first.
- **Interactive**: Requires confirmation before deleting files.
- **Recursive**: Cleans subdirectories as well.

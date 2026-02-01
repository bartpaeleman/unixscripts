# Database Master Tool

A comprehensive toolkit for managing MySQL/MariaDB databases on QNAP and macOS. Includes backup capabilities and python-powered statistical analysis.

## Usage

```bash
./db-master.sh
```

## Features

### 1. Backup
- **Secure**: Uses temporary credentials files to avoid CLI password exposure.
- **Compressed**: Creates `.sql.gz` archives.
- **Safe**: Auto-cleans failed partial backups.

### 2. Analysis
- **Python Integration**: Uses `db_stats.py` to query metadata.
- **Visual Stats**: Displays a formatted table of:
    - Table Names
    - Size (MB)
    - Row Counts
- **Health Check**: Quickly identify bloating tables.

## Requirements

- `mysql` client (and `mysqldump`)
- `python3` (for analysis)
- `gzip`

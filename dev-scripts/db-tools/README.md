# Database Backup Tool

A secure wrapper script for `mysqldump` to quickly create gzipped backups of MySQL or MariaDB databases. Designed for QNAP and macOS development environments.

## Usage

```bash
./db-backup.sh
```

## Features

- **Interactive**: Prompts for database details (Name, User, Host).
- **Secure**: Handles password input securely (hides typing) and avoids "password on command line" warnings by using temporary config files.
- **Compressed**: Automatically gzips the output file to save space.
- **Auto-Detection**: Attempts to locate `mysqldump` in common QNAP paths if not in global PATH.

## Requirements

- `mysqldump` (MySQL Client)
- `gzip`
- Bash shell

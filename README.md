# Developer Tools Collection

A comprehensive collection of development utilities and scripts designed for QNAP NAS and macOS environments.

## Repository Contents

This repository is organized into several toolsets:

### 1. Git Master Control Panel
A professional Git workflow manager to simplify development cycles.
*   **Location**: `git-master/`
*   **Key Features**: Environment management (PROD/DEV/TEST), automated branching, UAT workflows.
*   **Documentation**: [Full Docs](git-master/docs/README.md)

### 2. Development Scripts
Standalone utility scripts for web development and system maintenance.
*   **Location**: `dev-scripts/`

| Script | Description | Documentation |
| :--- | :--- | :--- |
| **Web Scaffold** | Generates standard HTML/PHP/CSS/JS project structures. | [Read More](dev-scripts/web-scaffold/README.md) |
| **DB Tools** | Database backup utilities for MySQL/MariaDB. | [Read More](dev-scripts/db-tools/README.md) |
| **Cleanup** | Removes `.DS_Store`, `Thumbs.db` and other system junk files. | [Read More](dev-scripts/cleanup/README.md) |

## Quick Start

### Installing Git Master
```bash
cd git-master
chmod +x install.sh
./install.sh
./git-master.sh
```

### Using Development Scripts
Scripts are standalone and can be run directly:
```bash
# Example: Create a new web project
./dev-scripts/web-scaffold/scaffold.sh

# Example: Backup database
./dev-scripts/db-tools/db-backup.sh
```

## Requirements
*   Bash Shell
*   Git
*   (Optional) MySQL Client for DB tools

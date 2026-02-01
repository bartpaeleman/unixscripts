# Developer Tools Collection

A comprehensive collection of development utilities and scripts designed for QNAP NAS and macOS environments.

## Quick Start

Initialize all tools with a single command:

```bash
chmod +x dev-tools.sh
./dev-tools.sh
```

## Repository Contents

### 1. Git Master Control Panel
A professional Git workflow manager to simplify development cycles.
*   **Location**: `git-master/`
*   **Key Features**: Environment management (PROD/DEV/TEST), automated branching, UAT workflows.
*   **Documentation**: [Full Docs](git-master/docs/README.md)

### 2. Development Scripts
Standalone utility scripts for web development and system maintenance.

| Script Suite | Description | Documentation |
| :--- | :--- | :--- |
| **Web Scaffold** | Generates standard projects with auto-documentation support. | [Read More](web-scaffold/README.md) |
| **DB Master** | Database backup and statistical analysis toolkit. | [Read More](db-tools/README.md) |
| **Container Master** | Interactive Docker management and inspection. | [Read More](container-master/README.md) |
| **Network Master** | Comprehensive network diagnostics and port scanning. | [Read More](network-master/README.md) |
| **CSV Master** | Advanced CSV viewing, conversion and JSON export. | [Read More](csv-master/README.md) |
| **Text Master** | Text analysis, comparison, and manipulation tools. | [Read More](text-master/README.md) |
| **Cleanup Master** | System junk removal and duplicate file finder. | [Read More](cleanup/README.md) |

## Usage Examples

Scripts are standalone and have their own interactive menus. After running `./dev-tools.sh`, you can execute them directly:

```bash
# Manage Containers
./container-master/container-master.sh

# Database Tools
./db-tools/db-master.sh

# Network Diagnostics
./network-master/network-master.sh

# Manipulate CSVs
./csv-master/csv-master.sh

# Create Web Project
./web-scaffold/scaffold.sh
```

## Requirements
*   Bash Shell
*   Git
*   Python 3 (Required for Analysis, Stats, and Scanning features)
*   Standard utilities (mysql, docker, etc.)

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

| Script Suite | Description | Documentation |
| :--- | :--- | :--- |
| **Web Scaffold** | Generates standard projects with auto-documentation support. | [Read More](dev-scripts/web-scaffold/README.md) |
| **DB Master** | Database backup and statistical analysis toolkit. | [Read More](dev-scripts/db-tools/README.md) |
| **Container Master** | Interactive Docker management and inspection. | [Read More](dev-scripts/container-master/README.md) |
| **Network Master** | Comprehensive network diagnostics and port scanning. | [Read More](dev-scripts/network-master/README.md) |
| **Cleanup Master** | System junk removal and duplicate file finder. | [Read More](dev-scripts/cleanup/README.md) |

## Quick Start

### Installing Git Master
```bash
cd git-master
chmod +x install.sh
./install.sh
./git-master.sh
```

### Using Development Scripts
Scripts are standalone and have their own interactive menus:

```bash
# Example: Manage Containers
./dev-scripts/container-master/container-master.sh

# Example: Database Tools
./dev-scripts/db-tools/db-master.sh

# Example: Network Diagnostics
./dev-scripts/network-master/network-master.sh
```

## Requirements
*   Bash Shell
*   Git
*   Python 3 (Required for Analysis, Stats, and Scanning features)
*   Standard utilities (mysql, docker, etc.)

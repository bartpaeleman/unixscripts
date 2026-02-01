# Developer Tools Collection

A comprehensive collection of development utilities and scripts designed for QNAP NAS and macOS environments.

## Quick Start

Initialize all tools with a single command:

```bash
chmod +x dev-tools.sh
./dev-tools.sh
```

This will set executable permissions and offer to install persistent aliases.

## Central Hub: Script Master

After initialization, you can access all tools via the central hub:

```bash
./script-master.sh
```

Or if aliases are installed: `scriptmaster`

## Repository Contents

### 1. Git Master Control Panel
A professional Git workflow manager to simplify development cycles.
*   **Location**: `git-master/`
*   **Key Features**: Environment management (PROD/DEV/TEST), automated branching, UAT workflows.

### 2. Development Scripts
Standalone utility scripts for web development and system maintenance.

| Script Suite | Description | Alias |
| :--- | :--- | :--- |
| **Web Scaffold** | Generates standard projects with auto-documentation support. | `scaffold` |
| **DB Master** | Database backup and statistical analysis toolkit. | `dbmaster` |
| **Container Master** | Interactive Docker management and inspection. | `dockermaster` |
| **Network Master** | Comprehensive network diagnostics and port scanning. | `netmaster` |
| **Data Master** | Advanced CSV/JSON/XML/YAML conversion, viewing, and normalization. | `datamaster` |
| **File Master** | Bulk rename (regex), archive (zip/tar), junk cleanup, and comparison. | `filemaster` |
| **Text Master** | Text analysis, search & replace, and file merging. | `textmaster` |

## Usage Examples

Scripts are standalone and have their own interactive menus. After running `./dev-tools.sh`, you can execute them directly or via aliases.

```bash
# Data Master (Convert CSV to JSON)
datamaster
# Select option 3 (Convert Format)

# File Master (Clean junk files like .DS_Store)
filemaster
# Select option 4 (Cleanup)

# Text Master (Compare files)
textmaster
# Select option 3 (Compare)
```

## Requirements
*   Bash Shell
*   Git
*   Python 3 (Required for Analysis, Stats, Scanning, and Data Conversion)
*   Standard utilities (mysql, docker, etc.)

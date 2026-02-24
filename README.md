# Developer Tools Collection

A comprehensive collection of development utilities and scripts designed for QNAP NAS and macOS environments.

## Installation

For a robust setup, use the interactive installer. This script will:
1.  Ask where you want to install the tools (default: `~/dev-tools`).
2.  Copy all necessary files to that location.
3.  Configure your environment (`.env`) with GitHub credentials.
4.  Set up aliases and permissions automatically.

```bash
chmod +x install.sh
./install.sh
```

Follow the on-screen prompts to complete the installation.

## Quick Start (Manual)

If you prefer to run the tools from the current directory without a full installation:

```bash
chmod +x dev-tools.sh
./dev-tools.sh
```

This will set executable permissions and offer to install persistent aliases for the current location.

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
*   **Key Features**: Environment management (PROD/DEV/TEST), automated branching, UAT workflows, and new "Checkout Repo" feature.

### 2. Development Scripts
Standalone utility scripts for web development and system maintenance.

| Script Suite | Description | Alias |
| :--- | :--- | :--- |
| **Web Scaffold** | Generates standard projects with auto-documentation support. | `scaffold` |
| **DB Master** | Database backup and statistical analysis toolkit. | `dbmaster` |
| **Container Master** | Interactive Docker management and inspection. | `dockermaster` |
| **Network Master** | Comprehensive network diagnostics and port scanning. | `netmaster` |
| **Data Master** | Advanced CSV/JSON/XML/YAML conversion, viewing, and normalization. | `datamaster` |
| **File Master** | Bulk rename, archive, granular cleanup (Junk/Empty/Dupes), and comparison. Defaults to current directory. | `filemaster` |
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

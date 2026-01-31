# Git Master Control Panel

Professional Git workflow manager for QNAP NAS and macOS, designed to streamline development cycles on GitHub.

## Overview

This repository contains the **Git Master Control Panel**, a command-line interface tool that simplifies complex Git operations, environment management, and release workflows.

### Key Features

*   **Environment Management**: Switch between PROD, DEV, and TEST environments effortlessly.
*   **Branch Operations**: Simplified creating, switching, and merging of branches.
*   **UAT & Release**: Tools for User Acceptance Testing and staging releases.
*   **Maintenance**: Utilities for cleaning up branches, undoing commits, and emergency resets.
*   **Cross-Platform**: optimized for QNAP NAS and macOS.

## Contents

*   `git-master/git-master.sh`: The main control panel script.
*   `git-master/install.sh`: Interactive installation script.
*   `git-master/docs/`: Detailed documentation.

## Quick Start

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd <repository-directory>
    ```

2.  **Run the installer:**
    Navigate to the `git-master` directory and run the install script.
    ```bash
    cd git-master
    chmod +x install.sh
    ./install.sh
    ```

3.  **Launch:**
    ```bash
    ./git-master.sh
    ```

For detailed usage instructions, configuration options, and troubleshooting, please refer to the [Full Documentation](git-master/docs/README.md).

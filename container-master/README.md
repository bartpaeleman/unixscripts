# Container Master Control Panel

A robust, interactive shell script for managing Docker containers on QNAP Container Station, macOS, or any Linux environment.

## Features

- **Interactive Menu**: Manage containers without memorizing Docker CLI commands.
- **Monitoring**: View running containers, status, and live logs.
- **Advanced Inspection**: Uses Python to parse complex JSON output from `docker inspect` into a human-readable summary (IPs, Ports, Volumes).
- **Lifecycle Management**: Start, stop, restart, and remove containers.
- **Stack Creation**: Quickly deploy stacks using pre-defined Docker Compose templates (LAMP, Node.js).
- **Cleanup**: Utilities to prune unused images, containers, and volumes.

## Installation

### QNAP NAS
1. SSH into your QNAP.
2. Navigate to this folder.
3. Run the script:
   ```bash
   ./container-master.sh
   ```

### macOS / Linux
Ensure Docker Desktop or Docker Engine is installed and running.

```bash
chmod +x container-master.sh
./container-master.sh
```

## Templates

The `templates/` directory contains Docker Compose files for common stacks.
- **lamp-stack**: PHP 8.2, Apache, MariaDB, phpMyAdmin.
- **node-app**: Node.js 18 development environment.

## Requirements

- Docker / Container Station
- Bash Shell
- Python 3 (for Advanced Inspection)

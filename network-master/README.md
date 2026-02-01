# Network Master Control Panel

A comprehensive network diagnostic and management toolkit designed for QNAP NAS and macOS. It aggregates common command-line network utilities into a user-friendly, menu-driven interface.

## Features

- **Consolidated Interface**: Access all your network tools from a single script.
- **Cross-Platform**: Checks for available commands and adapts (e.g., handles `ifconfig` vs `ip`).
- **Python Integration**: Includes a Python-based TCP port scanner.
- **Categorized Menus**:
  - **Interfaces**: `ifconfig`, `ip`, `route`, `arp`
  - **Connectivity**: `ping`, `traceroute`
  - **DNS**: `nslookup`, `dig`
  - **Statistics**: `netstat`, `ss`
  - **Web**: `curl`, `wget`, Public IP check

## Usage

```bash
# Make executable (if not already)
chmod +x network-master.sh

# Run
./network-master.sh
```

## Requirements

- Bash Shell
- Standard network utilities (`ping`, `curl`, `netstat`, etc.)
- Python 3 (optional, for the Port Scanner module)

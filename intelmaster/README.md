# Threat Intelligence Aggregator (IntelMaster)

IntelMaster is a Threat Intelligence Aggregator designed for macOS. It automates the collection, parsing, and filtering of security advisories, CVE databases, and RSS feeds, producing a clean, professional, dark-mode HTML dashboard.

## Features
- **Lightweight**: Written in Bash and Python 3. No heavy external dependencies.
- **Customizable**: Add any RSS or JSON source via a simple configuration file.
- **Secure**: Uses `launchd` for native macOS scheduling, proper file permissions, and sanitizes input to avoid Cross-Site Scripting (XSS) in generated reports.
- **Offline Output**: Generates standalone HTML files embedding CSS.

## Installation

1. **Clone or Download** the repository to your preferred location (e.g., `~/intelmaster`).
2. **Set Permissions**: Ensure the main script and config file are secure.
   ```bash
   cd ~/intelmaster
   chmod 700 threat-intel.sh
   chmod 600 config.json
   ```
3. **Verify Python 3**: Ensure Python 3 is installed (`python3 --version`). macOS comes with Python 3 via developer tools or Homebrew.

## Usage

Run the script manually:
```bash
./threat-intel.sh
```
Check the `/public` directory for the generated HTML report.

## Scheduling with launchd (macOS)

To automate the script to run daily at 8:00 AM using macOS's native `launchd`:

1. **Create a plist file**:
   Save the following XML as `~/Library/LaunchAgents/com.user.intelmaster.plist`. Replace `/Users/yourusername/intelmaster/threat-intel.sh` with the absolute path to your script.

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key>
       <string>com.user.intelmaster</string>
       <key>ProgramArguments</key>
       <array>
           <string>/Users/yourusername/intelmaster/threat-intel.sh</string>
       </array>
       <key>StartCalendarInterval</key>
       <dict>
           <key>Hour</key>
           <integer>8</integer>
           <key>Minute</key>
           <integer>0</integer>
       </dict>
       <key>StandardOutPath</key>
       <string>/tmp/intelmaster.log</string>
       <key>StandardErrorPath</key>
       <string>/tmp/intelmaster.error.log</string>
   </dict>
   </plist>
   ```

2. **Load the Launch Agent**:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.user.intelmaster.plist
   ```

*(Alternatively, you can use `cron` on Linux/macOS: `0 8 * * * /path/to/intelmaster/threat-intel.sh`)*

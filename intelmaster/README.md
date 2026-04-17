# Threat Intelligence Aggregator (IntelMaster)

IntelMaster is a Threat Intelligence Aggregator designed for macOS and QNAP NAS environments. It automates the collection, parsing, and filtering of security advisories, CVE databases, Atom feeds, and RSS feeds, producing an interactive, professional, dark-mode HTML dashboard.

## Features
- **Lightweight & Cross-Platform**: Written in Bash and Python 3. Supports QNAP NAS environments out of the box with custom `html` escaping fallbacks and POSIX-compliant bash logic. No heavy external dependencies.
- **Customizable**: Add any RSS, Atom, HTML, or JSON source via the interactive menu or a text/CSV list.
- **Interactive UI**: The generated single-page HTML report features real-time search filtering, clickable stat cards for quick data isolation, and dynamic detail panes for expanding threat cards.
- **Filtering**: Native support for filtering threat streams by General Security Info, Patches & Vulnerabilities, or other cyber topics via `INTEL_FILTER` environment variables.
- **Feed Management**: Contains robust tools to auto-deactivate failing feeds, paginate through existing feeds to toggle them on/off, and import bulk feeds via CSV (`Name,Hyperlink`).
- **Secure**: Implements proper file permissions and strict input sanitation to prevent Cross-Site Scripting (XSS) in generated reports.
- **Offline Output**: Generates standalone HTML files with embedded CSS and JavaScript logic.

## Installation

1. **Clone or Download** the repository to your preferred location (e.g., `~/intelmaster`), or run the `install.sh` script at the root of the project to setup the full `dev-tools` suite.
2. **Set Permissions**: Ensure the main script and config file are secure.
   ```bash
   cd ~/intelmaster
   chmod 700 threat-intel.sh
   chmod 600 config.json
   ```
3. **Verify Python 3**: Ensure Python 3 is installed (`python3 --version`). If dependencies like `dateutil` are missing, use Option 8 in the main menu to install them.

## Usage

IntelMaster includes a standalone interactive menu. Run the script manually to access it:
```bash
./threat-intel.sh
```

**Menu Options:**
1. **Run Threat Intel Aggregator (All/Default)**
2. **Run Threat Intel Aggregator (General Security Info)**
3. **Run Threat Intel Aggregator (Patches & Vulnerabilities)**
4. **Run Threat Intel Aggregator (Other Cyber Sec Topics)**
5. **Edit Config (config.json)**
6. **Add New Source to Config**
7a. **Manage Feeds from List (Text File/CSV)**
7b. **Toggle Feeds Interactively**
8. **Install Dependencies (Python)**

Reports are generated and saved in the `/public` directory.

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

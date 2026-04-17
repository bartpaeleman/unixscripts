# User Manual

This manual explains how to configure IntelMaster to suit your company's technology stack and threat monitoring requirements.

## 1. Modifying Configuration (`config.json`)

All settings are managed in `config.json`. The file is strictly structured in JSON format.

### Adding New Sources
You can add RSS feeds or specific JSON APIs (like CISA KEV).

```json
"sources": [
  {
    "name": "BleepingComputer",
    "url": "https://www.bleepingcomputer.com/feed/",
    "type": "rss"
  },
  {
    "name": "New Source",
    "url": "https://example.com/security.xml",
    "type": "rss"
  }
]
```
*Note: Currently supported `type` values are `"rss"` and `"cisa_kev"`.*

### Adding Technologies
Technologies (previously 'keywords') are case-insensitive. Add the technologies your company uses so the analyzer only flags relevant threats. These will appear as blue badges in your report.

```json
"technologies": [
  "Kubernetes",
  "Nginx",
  "Fortigate",
  "React",
  "macOS"
]
```

### Adding Inclusions (Overrides Exclusions)
You can define case-insensitive inclusion words. These are high-priority terms (e.g., "Zero-day", "RCE"). If an item contains an inclusion word, it will **always** be included in the report, overriding any exclusions or lack of technology matches. These will appear as bright green badges in your report.

```json
"inclusions": [
  "Zero-day",
  "RCE",
  "Critical update"
]
```

### Adding Exclusions
You can define case-insensitive exclusion words. If an item contains any of these words, it will be skipped entirely—unless it matches an inclusion word. This helps reduce noise from irrelevant categories (e.g., general CVE announcements or low severity notes).

```json
"exclusions": [
  "vulnerability",
  "CVE",
  "patch Tuesday",
  "low severity"
]
```

### Filtering Parameters
Adjust the `lookback_days` parameter to define how far back the analyzer should look for threats.
*Example: Setting to `7` will only show matches published in the last 7 days.*

```json
"parameters": {
  "minimum_severity": "High",
  "lookback_days": 7
}
```
*(Note: `minimum_severity` is a placeholder for future feature expansion such as mapping CVSS scores.)*

## 2. Managing Feeds & Configuration
IntelMaster includes a built-in menu to manage feeds and filter parameters interactively.
Run `./threat-intel.sh` to open the interactive menu.

- **Add New Source:** Manually type in a name, URL, and type (`rss`, `atom`, `html`, or `cisa_kev`).
- **Manage Active Feeds (Interactive Toggle):** Opens a paginated CLI menu where you can quickly turn feeds ON or OFF using their assigned numbers. You can also use `a` to activate all or `o` to deactivate all.
- **Manage Technologies / Inclusions / Exclusions:** Interactive CLI menus to add or delete strings from your configuration file without having to edit the JSON manually.
- **Auto-Deactivation:** If a feed URL fails to download (e.g., HTTP 404 or timeout), IntelMaster will automatically toggle its `"active"` state to `false` in `config.json` to prevent future hang-ups.

## 3. Topic Filtering
When running the aggregator from the menu, you can choose specific topic filters:
- **General Security Info:** Focuses on breaches, hacks, and data leaks.
- **Patches & Vulnerabilities:** Prioritizes CVEs, zero-days, and patch announcements.
- **Other Cyber Sec Topics:** Focuses on malware, ransomware, phishing, and botnets.

These options dynamically override your inclusions/exclusions for that specific run to categorize the resulting report.

## 4. Reading the Interactive Reports
- Reports are saved in your configured `output_dir` (defaults to the `/public` directory).
- The filenames include timestamps (e.g., `intel_report_YYYYMMDD_HHMMSS.html`).
- Open the HTML file in any modern web browser to view the dashboard.
- **Advanced Search & Filtering:** Use the search bar at the top to filter cards in real-time. The search is case-insensitive and supports **comma-separated multi-filtering**. For example: `source:The Hacker News, technology:chrome, inclusion:vulnerability`. By default, this applies **AND** logic (a card must match all filters). Check the **OR Mode** checkbox to match cards that hit *any* of the filters.
- **Fuzzy Match:** Toggle the "Fuzzy Match" checkbox next to the search bar to find approximate matches (useful for misspellings).
- **Auto-Expand Details:** When a search or filter is active, any parent source section (`<details>`) containing matching threat cards will automatically uncollapse to reveal its contents.
- **Interactive Filter Modals:** Click on the "Active Sources", "Monitored Tech", or "Inclusions" stat boxes at the top to open a modal window. Clicking any value inside the modal automatically appends the correct prefix (e.g., `technology:XXXX`) into the search filter and updates the view.
- **In-Text Highlighting:** Any matched technology or inclusion words will be visibly highlighted directly within the threat titles and summaries.
- **Dynamic Details:** The threat cards are displayed in a condensed view. Click on any threat card to dynamically load its full summary and hyperlink into a fixed detail pane at the bottom of your screen.
- **View Configuration:** Use the "View Config" button in the top right to see a popup modal of your actively applied technologies, inclusions, exclusions, and parameters (`minimum_severity`, `lookback_days`) used to generate the report.

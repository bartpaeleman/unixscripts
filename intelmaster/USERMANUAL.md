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

### Adding Keywords
Keywords are case-insensitive. Add the technologies your company uses so the analyzer only flags relevant threats.

```json
"keywords": [
  "Kubernetes",
  "Nginx",
  "Fortigate",
  "React",
  "macOS"
]
```

### Adding Inclusions (Overrides Exclusions)
You can define case-insensitive inclusion words. These are high-priority terms (e.g., "Zero-day", "RCE"). If an item contains an inclusion word, it will **always** be included in the report, overriding any exclusions or lack of keyword matches.

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

## 2. Reading the Reports
- Reports are saved in the `/public` directory.
- The filenames include timestamps (e.g., `intel_report_YYYYMMDD_HHMMSS.html`).
- Open the HTML file in any modern web browser to view the dashboard.

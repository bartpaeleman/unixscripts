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

# Cyber-Master

Cyber-Master is a modular cybersecurity toolset for macOS and Linux, built in Python and Bash. It utilizes a powerful **Unified JSON Schema** passed via standard Unix pipelines (`stdin`/`stdout`) allowing different intelligence modules to seamlessly communicate and chain together.

## Installation & Setup

1. **Clone the repository** (if not already done).
2. **Navigate** into the `cyber-master` folder.
3. **Configuration**:
   Copy the keys template and populate it with your actual API keys.
   ```bash
   # Add your API keys to this file
   nano config/keys.yaml
   ```
   Alternatively, you can provide these via environment variables (e.g., `VT_API_KEY`).
4. **Dependencies**:
   The `cyber.sh` and `common/run_python.sh` wrappers will **automatically** check and install the necessary Python packages from `requirements.txt` upon their first execution.
5. System Requirements:
   Ensure you have standard Unix tools like `whois` and `host` installed on your machine.

## Architecture

The toolset is highly modular, with each folder representing a distinct step in a cybersecurity investigation.

- `common/`: Core utilities including the Pydantic JSON schema (`UnifiedSchema`), logging configurations, and Bash wrapper functions.
- `mail/`: The **Phishing Email Analyzer** extracting relay chains, SPF/DKIM data, and anomalies.
- `enrich/`: The **Passive DNS & URL Enricher** utilizing async APIs to gather WHOIS, ASN, VirusTotal, and TLS certificate information.
- `scoring/`: The **Contextual Risk Scoring Engine** calculating penalty points dynamically based on module outputs.
- `reporting/`: The **Reporter Module** which translates the final JSON payload into readable Markdown or HTML reports.
- `templates/`: Jinja2 templates used by the reporting module.

## Usage Guide

You can access the functionality using the Master Wrapper script (`cyber.sh`), or by importing the bash functions into your `.zshrc`.

### Master Wrapper (`cyber.sh`)

The root `cyber.sh` script acts as the main entry point:

```bash
./cyber.sh --help
```

**Commands:**
- `mail <file>`: Run the Phishing Email Analyzer TUI on an `.eml` file.
- `enrich <target>`: Run the Passive DNS & URL Enricher. Outputs JSON.
- `score`: Run the Risk Scorer. Expects JSON via `stdin`.
- `report [format]`: Generate a report (default: `md`). Expects JSON via `stdin`.

**Pipeline Wrappers (Aliases):**
- `threatctx <target>`: Runs the full enrichment -> scoring -> reporting pipeline automatically.
- `mhdr <file>`: Analyzes an email and extracts only key findings via `jq`.
- `mailtrace <file>`: Directly analyzes an email and shows the rich Terminal UI.

**Interactive Mode:**
- `interactive`: Start the interactive wizard to guide you through analyzing an Email or doing Recon on a Domain/IP. Allows selecting output formats (Terminal UI, JSON, HTML/MD/PDF).

### Addressed Use-Cases & Mapping

The `cyber-master` suite is built to cover several crucial, daily SOC / Analyst workflows via its modular approach:

- **Recon & Threat Intel (Passive DNS + ASN + Hosting Correlator):** Addressed via the `enrich` module. Utilizing `httpx` to gather ASN/ISP intel (`ip-api`), checking AbuseIPDB, querying VirusTotal, and now integrated **Shodan** support for IP targets to list open ports and vulnerabilities.
- **Network Analysis (TLS Auditor):** Addressed via the `enrich` module's TLS capabilities (`ssl.getpeercert`). It assesses issuer information and certificate expiry to discover anomalies like free certificates (Let's Encrypt) used on financial targets.
- **Contextual Risk Scoring Engine:** Addressed via the `score` module. Centralizes inputs from `mail` and `enrich` to evaluate penalty points based on anomalies (e.g., mismatched routing, DMARC failures, bulletproof ASN hosters, newly registered domains, Shodan exposed sensitive ports).
- **Email / Phishing Analysis Tooling:** Addressed via the `mail` module. Validates SPF/DKIM/DMARC headers, traces relay chains step-by-step extracting delays, detects mismatched display names vs return-paths, and extracts attachments/URLs. Includes a Terminal UI (`mailtrace`) for visual analysts and strict JSON pipelines for automated triage.

### Examples

**1. Automated Threat Context Pipeline**
To automatically enrich a domain, calculate its risk score, and generate a report:
```bash
./cyber.sh threatctx example.com
```
This will produce a file named `report_example.com.md`.

**2. Manual Pipeline Chaining**
If you want to view the JSON output at any stage or build a custom pipeline:
```bash
./cyber.sh enrich bad-domain.com | ./cyber.sh score > output.json
```

**3. Phishing Email Analysis**
Analyze an `.eml` file with the visual terminal interface:
```bash
./cyber.sh mailtrace suspicious_email.eml
```

Or extract just the key findings (Origin IP, SPF, DKIM, Risk Score):
```bash
./cyber.sh mhdr suspicious_email.eml
```

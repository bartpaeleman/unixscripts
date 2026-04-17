# Changelog

All notable changes to this project will be documented in this file.

## [1.4.0] - Advanced UI Filtering, Auto-Expand, and Parameter Management

### Added
- **Advanced Multi-Filtering (AND/OR):** The search bar in the generated HTML report now supports comma-separated filters (e.g., `source:CISA, keyword:windows`) to apply multiple filtering criteria simultaneously. Added an "OR Mode" checkbox to switch between AND and OR logic for multiple filters.
- **Fuzzy Matching:** Added a "Fuzzy Match" checkbox in the HTML report to enable approximate subsequence searching (Levenshtein distance).
- **Auto-Expand Source Details:** Filtering the report now automatically expands (uncollapses) the relevant source `<details>` elements that contain matching threat cards.
- **Interactive Stat Modals:** Clicking the dashboard stat boxes now opens a modal window displaying available filters, allowing you to click and auto-append specific sources, keywords, or inclusions directly into the search bar.
- **Configuration Viewer Enhancement:** The "View Config" modal in the HTML report now displays `minimum_severity` and `lookback_days` parameters.
- **Parameter Management Menu:** Added an interactive CLI option to `threat-intel.sh` to seamlessly modify the output directory, minimum severity, and lookback days configurations.

## [1.3.0] - Interactive UI, Feed Management, and Cross-Platform Fixes

### Added
- **Atom and HTML Feed Parsing:** Added support for extracting threat intelligence from Atom XML feeds and raw HTML pages via naive regex lexing in `analyzer.py`.
- **Interactive HTML Dashboard:** The generated report now features real-time search filtering, clickable stat cards for categorization, and a master-detail view where clicking a condensed threat card displays full details in a fixed bottom pane.
- **Standalone Interactive Menu:** The `intelmaster_menu` is now housed directly within `threat-intel.sh` for native interactive execution, offering topic-based run options (e.g., General Security, Patches).
- **Bulk Feed Management:** Introduced `manage_feeds.py` to activate/deactivate feeds via plain text lists or CSV files (`Name,Hyperlink`), accessible from the new main menu.
- **Interactive Feed Toggling:** Added `interactive_toggle.py` for a paginated CLI menu to quickly turn feeds ON/OFF.
- **Auto-Deactivation:** Failing feeds during the `curl` phase are now automatically deactivated in `config.json` to prevent repeated timeouts.
- **Cross-Platform Compatibility:** Added a manual string replacement fallback for HTML escaping to support QNAP NAS environments lacking the standard Python `html` module.
- **Dependency Installer:** Added an interactive menu option to install missing Python dependencies (`python-dateutil`) via `pip`.
- **Safe Updater Script:** Added a root-level `update.sh` script to pull suite updates safely without overwriting user `config.json` or `.env` credentials.

## [1.2.0] - Add Inclusions Feature

### Added
- Feature to force-include threat items based on `inclusions` words in `config.json`, which overrides `exclusions` and `keywords`.

## [1.1.0] - Add Exclusions Feature

### Added
- Feature to omit threat items based on `exclusions` words defined in `config.json`.

## [1.0.0] - Initial Release

### Added
- Core Bash script (`threat-intel.sh`) to download feeds safely via `curl` with masked User-Agent.
- Python 3 Analyzer (`src/analyzer.py`) using Object-Oriented principles.
- Support for RSS and CISA KEV (JSON) format parsing.
- HTML sanitization to prevent XSS during report generation.
- Vanilla CSS (`assets/style.css`) providing a professional, dark-mode dashboard.
- Configurable settings via `config.json` (sources, keywords, lookback days).
- Comprehensive documentation (`README.md`, `USERMANUAL.md`).

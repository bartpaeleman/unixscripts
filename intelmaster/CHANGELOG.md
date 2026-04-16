# Changelog

All notable changes to this project will be documented in this file.

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

# CSV Master Tool

A professional utility for managing, viewing, and converting CSV files. It leverages Python for robust parsing (handling quoted fields correctly) and Bash for quick navigation.

## Usage

```bash
./csv-master.sh
```

## Features

### 1. ASCII Table Viewer
- **Smart Formatting**: Automatically detects delimiters (`,`, `;`, `TAB`).
- **Alignment**: Calculates column widths for perfect alignment.
- **Scrollable**: Uses `less -S` for easy horizontal scrolling of wide tables.

### 2. Delimiter Conversion
- **Robust**: Uses Python's `csv` module, so it correctly handles delimiters inside quoted strings (unlike simple `sed` replacements).
- **Flexible**: Supports Comma, Semicolon, Pipe, and Tab conversions.

### 3. Export to JSON
- Converts CSV rows into a JSON array of objects, using headers as keys.

### 4. Quick Stats
- Fast line counting for large files.

## Requirements

- Bash Shell
- Python 3 (Required for parsing logic)

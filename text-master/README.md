# Text Master Tool

A suite of utilities for manipulating, analyzing, and comparing plain text files using standard GNU tools and Python extensions.

## Usage

```bash
./text-master.sh
```

## Features

### 1. Analysis
- **Detailed Stats**: Uses Python to count lines, words, characters, and display the top 10 most frequent words.

### 2. Search & Replace
- **Interactive Grep**: Search for patterns with line numbers and color highlighting.
- **Safe Sed**: Find and replace text while automatically creating a `.bak` backup file.

### 3. Comparison
- **Diff Wrapper**: Visually compare two files with color output.

### 4. Transformation
- **Merge**: Concatenate multiple files.
- **Case Conversion**: Transform text to ALL CAPS or lowercase.

## Requirements

- Bash Shell
- Python 3 (for advanced stats)
- Standard Utils: `grep`, `sed`, `diff`, `tr`

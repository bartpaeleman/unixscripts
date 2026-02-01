import csv
import sys
import json
import argparse
import os

def detect_delimiter(first_line):
    if ";" in first_line: return ";"
    if "\t" in first_line: return "\t"
    return ","

def csv_to_table(filepath, delimiter=None):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            # Peek to sniff delimiter if not provided
            if not delimiter:
                first_line = f.readline()
                delimiter = detect_delimiter(first_line)
                f.seek(0)

            reader = csv.reader(f, delimiter=delimiter)
            rows = list(reader)

            if not rows:
                print("Empty CSV file.")
                return

            # Calculate column widths
            col_widths = [0] * len(rows[0])
            for row in rows:
                # Handle inconsistent row lengths
                if len(row) > len(col_widths):
                    col_widths.extend([0] * (len(row) - len(col_widths)))

                for i, cell in enumerate(row):
                    col_widths[i] = max(col_widths[i], len(str(cell)))

            # Print Table
            separator = "+" + "+".join(["-" * (w + 2) for w in col_widths]) + "+"

            print(separator)
            # Header
            header = rows[0]
            # Pad header if short
            header += [''] * (len(col_widths) - len(header))
            print("|" + "|".join([f" {cell:<{col_widths[i]}} " for i, cell in enumerate(header)]) + "|")
            print(separator)

            # Data
            for row in rows[1:]:
                # Pad row if short
                row += [''] * (len(col_widths) - len(row))
                print("|" + "|".join([f" {cell:<{col_widths[i]}} " for i, cell in enumerate(row)]) + "|")

            print(separator)
            print(f"Total Rows: {len(rows)}")

    except Exception as e:
        print(f"Error reading CSV: {e}")

def convert_delimiter(filepath, output_path, old_delim, new_delim):
    try:
        with open(filepath, 'r', encoding='utf-8') as fin, \
             open(output_path, 'w', encoding='utf-8', newline='') as fout:

            if not old_delim:
                 old_delim = detect_delimiter(fin.readline())
                 fin.seek(0)

            reader = csv.reader(fin, delimiter=old_delim)
            writer = csv.writer(fout, delimiter=new_delim)

            writer.writerows(reader)
        print(f"Successfully converted to {output_path}")
    except Exception as e:
        print(f"Error converting CSV: {e}")

def csv_to_json(filepath, output_path, delimiter=None):
    try:
        data = []
        with open(filepath, 'r', encoding='utf-8') as f:
             if not delimiter:
                 delimiter = detect_delimiter(f.readline())
                 f.seek(0)

             reader = csv.DictReader(f, delimiter=delimiter)
             for row in reader:
                 data.append(row)

        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4)
        print(f"Successfully exported to {output_path}")
    except Exception as e:
        print(f"Error exporting to JSON: {e}")

def main():
    parser = argparse.ArgumentParser(description="CSV Utility Tool")
    subparsers = parser.add_subparsers(dest="command")

    # View Command
    view_parser = subparsers.add_parser("view", help="View CSV as ASCII Table")
    view_parser.add_argument("file", help="Input CSV file")
    view_parser.add_argument("--delim", help="Delimiter (optional)", default=None)

    # Convert Command
    conv_parser = subparsers.add_parser("convert", help="Convert Delimiter")
    conv_parser.add_argument("file", help="Input CSV file")
    conv_parser.add_argument("output", help="Output CSV file")
    conv_parser.add_argument("--old", help="Old Delimiter", default=None)
    conv_parser.add_argument("--new", help="New Delimiter", required=True)

    # JSON Command
    json_parser = subparsers.add_parser("json", help="Convert to JSON")
    json_parser.add_argument("file", help="Input CSV file")
    json_parser.add_argument("output", help="Output JSON file")
    json_parser.add_argument("--delim", help="Delimiter (optional)", default=None)

    args = parser.parse_args()

    if args.command == "view":
        csv_to_table(args.file, args.delim)
    elif args.command == "convert":
        # Decode escaped characters like \t
        old = args.old.replace('\\t', '\t') if args.old else None
        new = args.new.replace('\\t', '\t')
        convert_delimiter(args.file, args.output, old, new)
    elif args.command == "json":
        delim = args.delim.replace('\\t', '\t') if args.delim else None
        csv_to_json(args.file, args.output, delim)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

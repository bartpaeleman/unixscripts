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

            # Pass 1: Calculate column widths
            try:
                first_row = next(reader)
            except StopIteration:
                print("Empty CSV file.")
                return

            col_widths = [len(str(cell)) for cell in first_row]
            row_count = 1

            for row in reader:
                row_count += 1
                if len(row) > len(col_widths):
                    col_widths.extend([0] * (len(row) - len(col_widths)))

                for i, cell in enumerate(row):
                    col_widths[i] = max(col_widths[i], len(str(cell)))

            # Pass 2: Print Table
            f.seek(0)
            reader = csv.reader(f, delimiter=delimiter)

            separator = "+" + "+".join(["-" * (w + 2) for w in col_widths]) + "+"

            print(separator)
            # Header
            header = next(reader)
            # Pad header if short
            header += [''] * (len(col_widths) - len(header))
            print("|" + "|".join([f" {cell:<{col_widths[i]}} " for i, cell in enumerate(header)]) + "|")
            print(separator)

            # Data
            for row in reader:
                # Pad row if short
                row += [''] * (len(col_widths) - len(row))
                print("|" + "|".join([f" {cell:<{col_widths[i]}} " for i, cell in enumerate(row)]) + "|")

            print(separator)
            print(f"Total Rows: {row_count}")

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
        with open(filepath, 'r', encoding='utf-8') as fin, \
             open(output_path, 'w', encoding='utf-8') as fout:

            if not delimiter:
                 delimiter = detect_delimiter(fin.readline())
                 fin.seek(0)

            reader = csv.DictReader(fin, delimiter=delimiter)

            fout.write("[\n")
            first = True
            for row in reader:
                if not first:
                    fout.write(",\n")
                first = False

                # Serialize row with indentation
                json_str = json.dumps(row, indent=4)
                # Indent the whole block
                indented_json_str = "\n".join("    " + line for line in json_str.split("\n"))
                fout.write(indented_json_str)

            fout.write("\n]")

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

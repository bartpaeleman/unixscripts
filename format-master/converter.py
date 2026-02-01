import argparse
import sys
import os
import json
import csv
import xml.etree.ElementTree as ET

# Dependency Checks
try:
    import pandas as pd
    PANDAS_AVAIL = True
except ImportError:
    PANDAS_AVAIL = False

try:
    import yaml
    YAML_AVAIL = True
except ImportError:
    YAML_AVAIL = False

def check_dependencies():
    print("Dependency Check:")
    print(f"  - pandas: {'OK' if PANDAS_AVAIL else 'MISSING (Install for advanced features)'}")
    print(f"  - pyyaml: {'OK' if YAML_AVAIL else 'MISSING (Install for YAML support)'}")

def convert_csv_to_json(input_file, output_file):
    print(f"Converting CSV {input_file} -> JSON {output_file}...")
    if PANDAS_AVAIL:
        try:
            df = pd.read_csv(input_file)
            df.to_json(output_file, orient='records', indent=4)
            print("Done (via Pandas).")
            return
        except Exception as e:
            print(f"Pandas failed: {e}. Falling back to std lib.")

    # Fallback
    try:
        data = []
        with open(input_file, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                data.append(row)
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4)
        print("Done (via Std Lib).")
    except Exception as e:
        print(f"Error: {e}")

def convert_json_to_csv(input_file, output_file):
    print(f"Converting JSON {input_file} -> CSV {output_file}...")
    if PANDAS_AVAIL:
        try:
            df = pd.read_json(input_file)
            df.to_csv(output_file, index=False)
            print("Done (via Pandas).")
            return
        except Exception as e:
            print(f"Pandas failed: {e}. Falling back to std lib.")

    # Fallback (simple flat JSON only)
    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)

        if not isinstance(data, list):
            print("Error: Standard lib conversion expects a list of objects.")
            return

        if not data:
            print("Error: Empty JSON data.")
            return

        keys = data[0].keys()
        with open(output_file, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=keys)
            writer.writeheader()
            writer.writerows(data)
        print("Done (via Std Lib).")
    except Exception as e:
        print(f"Error: {e}")

def convert_yaml(input_file, output_file, to_format):
    if not YAML_AVAIL:
        print("Error: PyYAML is not installed. Cannot process YAML.")
        return

    print(f"Converting YAML {input_file} -> {to_format} {output_file}...")
    try:
        with open(input_file, 'r') as f:
            data = yaml.safe_load(f)

        if to_format == 'json':
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=4)
        elif to_format == 'csv':
            # Assuming list of dicts
             if PANDAS_AVAIL:
                 df = pd.json_normalize(data)
                 df.to_csv(output_file, index=False)
             else:
                 print("Error: YAML to CSV requires Pandas for normalization.")
                 return
        elif to_format == 'yaml':
            # Just copy/reformat?
            with open(output_file, 'w') as f:
                yaml.dump(data, f)
        print("Done.")
    except Exception as e:
        print(f"Error: {e}")

def xml_to_dict(element):
    node = {}
    if element.attrib:
        node["@attributes"] = element.attrib

    if element.text and element.text.strip():
        text = element.text.strip()
        if not node:
             return text
        node["#text"] = text

    for child in element:
        child_data = xml_to_dict(child)
        if child.tag in node:
            if not isinstance(node[child.tag], list):
                node[child.tag] = [node[child.tag]]
            node[child.tag].append(child_data)
        else:
            node[child.tag] = child_data
    return node

def convert_xml_to_json(input_file, output_file):
    print(f"Converting XML {input_file} -> JSON {output_file}...")
    try:
        tree = ET.parse(input_file)
        root = tree.getroot()
        data = {root.tag: xml_to_dict(root)}

        with open(output_file, 'w') as f:
            json.dump(data, f, indent=4)
        print("Done.")
    except Exception as e:
        print(f"Error: {e}")

def convert_json_to_xml(input_file, output_file):
    print(f"Converting JSON {input_file} -> XML {output_file}...")
    print("Warning: JSON to XML is complex. Producing basic structure.")
    try:
        if PANDAS_AVAIL:
            # Pandas read_json -> to_xml is robust
            try:
                df = pd.read_json(input_file)
                df.to_xml(output_file)
                print("Done (via Pandas).")
                return
            except Exception as e:
                 print(f"Pandas XML conversion failed: {e}")

        print("Error: Robust JSON to XML requires Pandas or specific schema logic.")
    except Exception as e:
        print(f"Error: {e}")

def normalize_csv(input_file, output_file):
    print(f"Normalizing CSV {input_file}...")
    # Remove empty rows, strip whitespace
    if PANDAS_AVAIL:
        try:
            df = pd.read_csv(input_file)
            # Drop empty rows
            df.dropna(how='all', inplace=True)
            # Strip whitespace from string columns
            df = df.apply(lambda x: x.str.strip() if x.dtype == "object" else x)
            df.to_csv(output_file, index=False)
            print("Done (via Pandas).")
            return
        except Exception as e:
             print(f"Pandas failed: {e}.")

    print("Normalization requires Pandas for best results. Skipping.")

def main():
    parser = argparse.ArgumentParser(description="Data Format Converter")
    subparsers = parser.add_subparsers(dest='command')

    # Dependencies
    subparsers.add_parser('check')

    # Convert
    conv_parser = subparsers.add_parser('convert')
    conv_parser.add_argument('input_file')
    conv_parser.add_argument('output_file')
    conv_parser.add_argument('--format', choices=['json', 'csv', 'yaml', 'xml'], help="Target format (if not implied by extension)")

    # Normalize
    norm_parser = subparsers.add_parser('normalize')
    norm_parser.add_argument('input_file')
    norm_parser.add_argument('output_file')

    args = parser.parse_args()

    if args.command == 'check':
        check_dependencies()
    elif args.command == 'convert':
        in_ext = os.path.splitext(args.input_file)[1].lower()
        out_ext = os.path.splitext(args.output_file)[1].lower()

        if in_ext == '.csv' and out_ext == '.json':
            convert_csv_to_json(args.input_file, args.output_file)
        elif in_ext == '.json' and out_ext == '.csv':
            convert_json_to_csv(args.input_file, args.output_file)
        elif in_ext in ['.yaml', '.yml']:
            target = args.format if args.format else out_ext.replace('.', '')
            convert_yaml(args.input_file, args.output_file, target)
        elif in_ext == '.xml' and out_ext == '.json':
            convert_xml_to_json(args.input_file, args.output_file)
        elif in_ext == '.json' and out_ext == '.xml':
            convert_json_to_xml(args.input_file, args.output_file)
        else:
            print(f"Conversion from {in_ext} to {out_ext} not fully implemented yet.")
    elif args.command == 'normalize':
        if args.input_file.endswith('.csv'):
            normalize_csv(args.input_file, args.output_file)
        else:
            print("Normalization currently only supported for CSV.")

if __name__ == "__main__":
    main()

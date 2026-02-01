import argparse
import os
import re
import shutil
import hashlib
import zipfile
import tarfile
import datetime

def calculate_hash(filepath):
    hash_md5 = hashlib.md5()
    try:
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()
    except Exception as e:
        print(f"Error hashing {filepath}: {e}")
        return None

def bulk_rename(directory, pattern, replacement, dry_run=False):
    print(f"Bulk Renaming in {directory} (Pattern: '{pattern}' -> '{replacement}')")
    count = 0
    try:
        regex = re.compile(pattern)
        for root, dirs, files in os.walk(directory):
            for filename in files:
                if regex.search(filename):
                    new_filename = regex.sub(replacement, filename)
                    # Handle date placeholder {date}
                    if "{date}" in new_filename:
                        today = datetime.date.today().strftime("%Y-%m-%d")
                        new_filename = new_filename.replace("{date}", today)

                    old_path = os.path.join(root, filename)
                    new_path = os.path.join(root, new_filename)

                    if old_path != new_path:
                        print(f"  {filename} -> {new_filename}")
                        if not dry_run:
                            try:
                                os.rename(old_path, new_path)
                            except OSError as e:
                                print(f"    Error: {e}")
                        count += 1
    except re.error as e:
        print(f"Invalid Regex: {e}")
        return

    if dry_run:
        print(f"Dry run complete. {count} files would be renamed.")
    else:
        print(f"Renamed {count} files.")

def create_structure(template_file):
    print(f"Creating structure from {template_file}...")
    try:
        with open(template_file, 'r') as f:
            lines = f.readlines()

        for line in lines:
            path = line.strip()
            if path:
                if not os.path.exists(path):
                    try:
                        os.makedirs(path)
                        print(f"  Created: {path}")
                    except OSError as e:
                        print(f"  Error creating {path}: {e}")
                else:
                    print(f"  Exists: {path}")
    except Exception as e:
        print(f"Error reading template: {e}")

def archive_directory(directory, archive_type):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    base_name = os.path.basename(os.path.normpath(directory))
    archive_name = f"{base_name}_{timestamp}"

    print(f"Archiving {directory} to {archive_name}.{archive_type}...")

    if archive_type == 'zip':
        try:
            with zipfile.ZipFile(f"{archive_name}.zip", "w", zipfile.ZIP_DEFLATED) as zf:
                for root, dirs, files in os.walk(directory):
                    for file in files:
                        abs_path = os.path.join(root, file)
                        rel_path = os.path.relpath(abs_path, directory)
                        zf.write(abs_path, rel_path)
            print(f"Created {archive_name}.zip")
        except Exception as e:
            print(f"Error creating zip: {e}")

    elif archive_type == 'tar':
        try:
            with tarfile.open(f"{archive_name}.tar.gz", "w:gz") as tf:
                tf.add(directory, arcname=base_name)
            print(f"Created {archive_name}.tar.gz")
        except Exception as e:
            print(f"Error creating tar: {e}")

def cleanup(directory, delete_dupes=False, delete_empty=False, dry_run=False):
    print(f"Cleaning up {directory}...")

    if delete_dupes:
        print("Scanning for duplicates...")
        hashes = {}
        dupes_found = 0
        for root, dirs, files in os.walk(directory):
            for file in files:
                filepath = os.path.join(root, file)
                file_hash = calculate_hash(filepath)
                if file_hash:
                    if file_hash in hashes:
                        print(f"  Duplicate found: {filepath} (matches {hashes[file_hash]})")
                        dupes_found += 1
                        if not dry_run:
                            try:
                                os.remove(filepath)
                                print("    Deleted.")
                            except OSError as e:
                                print(f"    Error deleting: {e}")
                    else:
                        hashes[file_hash] = filepath
        if dry_run:
            print(f"Dry run: {dupes_found} duplicates found.")

    if delete_empty:
        print("Scanning for empty directories...")
        empty_found = 0
        # Walk bottom-up
        for root, dirs, files in os.walk(directory, topdown=False):
            if not os.listdir(root):
                print(f"  Empty directory: {root}")
                empty_found += 1
                if not dry_run:
                    try:
                        os.rmdir(root)
                        print("    Removed.")
                    except OSError as e:
                        print(f"    Error removing: {e}")
        if dry_run:
            print(f"Dry run: {empty_found} empty directories found.")

def compare_files(file1, file2):
    print(f"Comparing {file1} vs {file2}...")
    h1 = calculate_hash(file1)
    h2 = calculate_hash(file2)

    if h1 == h2:
        print("Files are IDENTICAL (Match by MD5).")
    else:
        print("Files are DIFFERENT.")
        print(f"  {file1}: {h1}")
        print(f"  {file2}: {h2}")

def main():
    parser = argparse.ArgumentParser(description="File Master Tool")
    subparsers = parser.add_subparsers(dest='command')

    # Rename
    ren_parser = subparsers.add_parser('rename')
    ren_parser.add_argument('directory')
    ren_parser.add_argument('pattern')
    ren_parser.add_argument('replacement')
    ren_parser.add_argument('--run', action='store_true', help="Execute the rename (default is dry-run)")

    # Structure
    struct_parser = subparsers.add_parser('structure')
    struct_parser.add_argument('template_file')

    # Archive
    arch_parser = subparsers.add_parser('archive')
    arch_parser.add_argument('directory')
    arch_parser.add_argument('--type', choices=['zip', 'tar'], default='zip')

    # Cleanup
    clean_parser = subparsers.add_parser('cleanup')
    clean_parser.add_argument('directory')
    clean_parser.add_argument('--dupes', action='store_true')
    clean_parser.add_argument('--empty', action='store_true')
    clean_parser.add_argument('--run', action='store_true')

    # Compare
    comp_parser = subparsers.add_parser('compare')
    comp_parser.add_argument('file1')
    comp_parser.add_argument('file2')

    args = parser.parse_args()

    if args.command == 'rename':
        bulk_rename(args.directory, args.pattern, args.replacement, dry_run=not args.run)
    elif args.command == 'structure':
        create_structure(args.template_file)
    elif args.command == 'archive':
        archive_directory(args.directory, args.type)
    elif args.command == 'cleanup':
        cleanup(args.directory, delete_dupes=args.dupes, delete_empty=args.empty, dry_run=not args.run)
    elif args.command == 'compare':
        compare_files(args.file1, args.file2)

if __name__ == "__main__":
    main()

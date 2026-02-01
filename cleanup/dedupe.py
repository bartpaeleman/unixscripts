import sys
import os
import hashlib

CHUNK_SIZE = 65536  # 64KB

def hash_file(filepath):
    """Returns MD5 hash of a file."""
    hasher = hashlib.md5()
    try:
        with open(filepath, 'rb') as f:
            while chunk := f.read(CHUNK_SIZE):
                hasher.update(chunk)
        return hasher.hexdigest()
    except (OSError, PermissionError):
        return None

def find_duplicates(directory):
    print(f"Scanning {directory} for duplicates...")
    hashes = {}
    duplicates = []

    for root, _, files in os.walk(directory):
        for file in files:
            path = os.path.join(root, file)
            file_hash = hash_file(path)

            if file_hash:
                if file_hash in hashes:
                    duplicates.append((path, hashes[file_hash]))
                else:
                    hashes[file_hash] = path

    return duplicates

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 dedupe.py <directory>")
        sys.exit(1)

    target_dir = sys.argv[1]
    if not os.path.isdir(target_dir):
        print("Invalid directory.")
        sys.exit(1)

    dupes = find_duplicates(target_dir)

    if not dupes:
        print("\nNo duplicates found.")
    else:
        print(f"\nFound {len(dupes)} duplicates:")
        for new, original in dupes:
            print(f"Duplicate: {new}")
            print(f"Original:  {original}")
            print("---")

        print("\n(Note: This script only lists duplicates. Manual deletion recommended for safety.)")

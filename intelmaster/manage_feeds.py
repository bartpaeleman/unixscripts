import json
import sys
import os

def toggle_feeds(config_path, list_path):
    if not os.path.exists(config_path):
        print(f"Error: {config_path} not found.")
        sys.exit(1)
    if not os.path.exists(list_path):
        print(f"Error: {list_path} not found.")
        sys.exit(1)

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error reading config: {e}")
        sys.exit(1)

    with open(list_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]

    sources = config.get('sources', [])
    current_urls = {s.get('url'): s for s in sources if s.get('url')}

    import csv
    # Check if CSV format
    is_csv = False
    if len(lines) > 0 and 'Hyperlink' in lines[0]:
        is_csv = True
        lines = lines[1:] # Skip header

    for line in lines:
        url = line
        name = ""

        if is_csv:
            parts = line.split(',', 1)
            if len(parts) == 2:
                name = parts[0].strip()
                url = parts[1].strip()
            else:
                url = parts[0].strip()

        if url.startswith('#') or url.startswith('-'):
            clean_url = url.lstrip('#-').strip()
            if clean_url in current_urls:
                print(f"Deactivating (removing): {clean_url}")
                del current_urls[clean_url]
        else:
            clean_url = url.strip()
            if not clean_url: continue

            if clean_url not in current_urls:
                feed_type = 'rss'
                if '.json' in clean_url:
                    feed_type = 'json'
                elif 'atom' in clean_url:
                    feed_type = 'atom'

                if not name:
                    name = clean_url.split('//')[-1].split('/')[0]

                print(f"Activating new source: {name} - {clean_url}")
                current_urls[clean_url] = {
                    "name": name,
                    "url": clean_url,
                    "type": feed_type,
                    "active": True
                }
            else:
                print(f"Already active: {clean_url}")
                current_urls[clean_url]['active'] = True

    config['sources'] = list(current_urls.values())

    try:
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        print("Config updated successfully.")
    except Exception as e:
        print(f"Error writing config: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 manage_feeds.py <config_path> <list_path>")
        sys.exit(1)

    toggle_feeds(sys.argv[1], sys.argv[2])

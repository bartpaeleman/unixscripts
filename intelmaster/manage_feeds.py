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

    # We will build a set of enabled URLs from the text file.
    # Lines starting with '#' are considered deactivated/ignored by the user
    # but let's assume the user just provides a clean list of URLs to activate.
    # We will only keep URLs in the config if they are in the list.
    # Alternatively, the prompt was "activate or deactivate from a file where I place the links".
    # Let's say any URL in the file will be active. URLs in config NOT in file will be removed (or we just add missing ones).
    # "activate or deactivate feeds from a list". A simple approach:
    # Read the text file. Lines starting with '#' or '-' are deactivated (removed).
    # Lines with plain URLs are activated (added).

    sources = config.get('sources', [])
    current_urls = {s.get('url'): s for s in sources if s.get('url')}

    for line in lines:
        if line.startswith('#') or line.startswith('-'):
            url = line.lstrip('#-').strip()
            if url in current_urls:
                print(f"Deactivating: {url}")
                del current_urls[url]
        else:
            url = line
            if url not in current_urls:
                # Basic guess for type based on extension
                feed_type = 'rss'
                if '.json' in url:
                    feed_type = 'json'
                elif 'atom' in url:
                    feed_type = 'atom'

                print(f"Activating new source: {url}")
                current_urls[url] = {
                    "name": url.split('//')[-1].split('/')[0],
                    "url": url,
                    "type": feed_type
                }
            else:
                print(f"Already active: {url}")

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

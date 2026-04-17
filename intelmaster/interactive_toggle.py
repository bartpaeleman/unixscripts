import json
import sys
import os

def interactive_toggle(config_path):
    if not os.path.exists(config_path):
        print(f"Error: {config_path} not found.")
        sys.exit(1)

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            config = json.load(f)
    except Exception as e:
        print(f"Error reading config: {e}")
        sys.exit(1)

    sources = config.get('sources', [])
    if not sources:
        print("No sources found in config.json.")
        sys.exit(0)

    while True:
        print("\n=== Threat Intel Feed Manager ===")
        for i, s in enumerate(sources):
            # Default to True if 'active' flag is missing
            is_active = s.get('active', True)
            status = "[ON] " if is_active else "[OFF]"
            print(f"{i+1}) {status} {s.get('name', 'Unknown')}")
        print("0) Save and Exit")

        try:
            choice = input("\nEnter number to toggle state (or 0 to exit): ")
            if not choice.strip():
                continue

            choice_idx = int(choice)
            if choice_idx == 0:
                break

            if 1 <= choice_idx <= len(sources):
                src = sources[choice_idx - 1]
                current_state = src.get('active', True)
                src['active'] = not current_state
                print(f"Toggled '{src.get('name')}' to {'ON' if not current_state else 'OFF'}")
            else:
                print("Invalid number.")
        except ValueError:
            print("Please enter a valid number.")
        except KeyboardInterrupt:
            print("\nExiting without saving.")
            sys.exit(0)

    # Save changes
    config['sources'] = sources
    try:
        with open(config_path, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
        print("\nConfig updated successfully.")
    except Exception as e:
        print(f"Error writing config: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 interactive_toggle.py <config_path>")
        sys.exit(1)

    interactive_toggle(sys.argv[1])

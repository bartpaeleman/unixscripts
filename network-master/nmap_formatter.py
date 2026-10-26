import sys
import xml.etree.ElementTree as ET
import urllib.request
import json
import os

YAML_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "ports.json")
IANA_URL = "https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml"

def update_database():
    print(f"Downloading port definitions from IANA ({IANA_URL})...")
    try:
        req = urllib.request.Request(IANA_URL, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            xml_data = response.read()

        print("Parsing XML data...")
        root = ET.fromstring(xml_data)
        namespace = {'iana': 'http://www.iana.org/assignments'}

        ports_db = {}
        for record in root.findall('.//iana:record', namespace):
            name = record.find('iana:name', namespace)
            number = record.find('iana:number', namespace)
            protocol = record.find('iana:protocol', namespace)
            description = record.find('iana:description', namespace)

            if number is not None and number.text and protocol is not None and protocol.text:
                port_num = number.text
                if '-' in port_num: continue # Skip ranges for simplicity

                try:
                    port_num = int(port_num)
                except ValueError:
                    continue

                desc = description.text if description is not None and description.text else (name.text if name is not None and name.text else "Unknown Service")
                desc = desc.replace('\n', ' ').strip()

                if str(port_num) not in ports_db:
                    ports_db[str(port_num)] = {}
                ports_db[str(port_num)][protocol.text.lower()] = desc

        with open(YAML_FILE, 'w') as f:
            json.dump(ports_db, f, indent=2)

        print(f"Successfully updated local database. Saved to {YAML_FILE}.")
    except Exception as e:
        print(f"Failed to update database: {e}")
        sys.exit(1)

def load_database():
    if os.path.exists(YAML_FILE):
        try:
            with open(YAML_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def format_nmap_xml(xml_file):
    ports_db = load_database()

    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
    except Exception as e:
        print(f"Failed to parse Nmap XML file: {e}")
        return

    for host in root.findall('host'):
        status = host.find('status')
        if status is None or status.attrib.get('state') != 'up':
            continue

        addresses = host.findall('address')
        ip = "Unknown IP"
        for addr in addresses:
            if addr.attrib.get('addrtype') == 'ipv4':
                ip = addr.attrib.get('addr')
                break

        hostnames = host.findall('hostnames/hostname')
        hostname = hostnames[0].attrib.get('name') if hostnames else ""

        host_title = f"{ip}"
        if hostname:
            host_title += f" ({hostname})"

        print(f"\n===============================================================")
        print(f" HOST: {host_title}")
        print(f"===============================================================")

        ports = host.find('ports')
        if ports is None:
            print(" No open ports found.")
            continue

        open_ports = []
        for port in ports.findall('port'):
            state = port.find('state')
            if state is None or state.attrib.get('state') != 'open':
                continue

            port_id = port.attrib.get('portid')
            protocol = port.attrib.get('protocol')

            service = port.find('service')
            service_name = service.attrib.get('name') if service is not None else "unknown"

            desc = "-"
            try:
                if str(port_id) in ports_db and protocol in ports_db[str(port_id)]:
                    desc = ports_db[str(port_id)][protocol]
            except:
                pass

            open_ports.append({
                'port': f"{port_id}/{protocol}",
                'service': service_name,
                'description': desc
            })

        if not open_ports:
            print(" No open ports found.")
        else:
            print(f" {'PORT':<12} | {'SERVICE':<15} | {'DESCRIPTION'}")
            print(f" {'-'*12}-+-{'-'*15}-+-{'-'*40}")
            for p in open_ports:
                desc = p['description']
                if len(desc) > 60:
                    desc = desc[:57] + "..."
                print(f" {p['port']:<12} | {p['service']:<15} | {desc}")

if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--update':
        update_database()
    elif len(sys.argv) > 1:
        format_nmap_xml(sys.argv[1])
    else:
        print("Usage: python3 nmap_formatter.py <nmap_xml_file> | --update")

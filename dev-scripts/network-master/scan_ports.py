import socket
import sys
import time

def scan_ports(target_ip, start_port, end_port):
    print(f"\nStarting TCP scan on {target_ip} ({start_port}-{end_port})...")
    start_time = time.time()

    try:
        for port in range(start_port, end_port + 1):
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(0.5)
            result = sock.connect_ex((target_ip, port))
            if result == 0:
                print(f"Port {port}: OPEN")
            sock.close()
    except KeyboardInterrupt:
        print("\nScan interrupted.")
        sys.exit()
    except socket.gaierror:
        print("Hostname could not be resolved.")
        sys.exit()
    except socket.error:
        print("Could not connect to server.")
        sys.exit()

    end_time = time.time()
    print(f"\nScan completed in {end_time - start_time:.2f} seconds.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 scan_ports.py <ip> <start_port> <end_port>")
        sys.exit(1)

    target = sys.argv[1]
    start = int(sys.argv[2])
    end = int(sys.argv[3])

    scan_ports(target, start, end)

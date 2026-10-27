import socket
import sys
import time
import threading

# Lock to ensure print output doesn't get interleaved
print_lock = threading.Lock()

def scan_port(target_ip, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.5)
    try:
        result = sock.connect_ex((target_ip, port))
        if result == 0:
            with print_lock:
                print(f"Port {port}: OPEN")
    except Exception:
        pass
    finally:
        sock.close()

def scan_ports(target_ip, start_port, end_port):
    print(f"\nStarting TCP scan on {target_ip} ({start_port}-{end_port})...")
    start_time = time.time()

    try:
        # Resolve hostname first to catch DNS errors early and avoid repeated lookups
        try:
            target_ip = socket.gethostbyname(target_ip)
        except socket.gaierror:
            print("Hostname could not be resolved.")
            sys.exit()
        except socket.error:
            print("Could not connect to server.")
            sys.exit()

        threads = []
        for port in range(start_port, end_port + 1):
            t = threading.Thread(target=scan_port, args=(target_ip, port))
            threads.append(t)
            t.start()
            if len(threads) >= 100:
                for t in threads:
                    t.join()
                threads = []
        for t in threads:
            t.join()
            # We use submit to start threads immediately
            # Wait for all futures to complete

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

import sys
import os
import subprocess
import re

def get_db_stats(host, user, db_name):
    password = os.environ.get('DB_PASS', '')
    # SQL query to get table sizes
    sql = f"""
    SELECT
        table_name AS "Table",
        ROUND(((data_length + index_length) / 1024 / 1024), 2) AS "Size (MB)",
        table_rows AS "Rows"
    FROM information_schema.TABLES
    WHERE table_schema = "{db_name}"
    ORDER BY (data_length + index_length) DESC;
    """

    # Determine the correct binary
    mysql_bin = None
    if subprocess.run(["which", "mariadb"], stdout=subprocess.DEVNULL).returncode == 0:
        mysql_bin = "mariadb"
    elif subprocess.run(["which", "mysql"], stdout=subprocess.DEVNULL).returncode == 0:
        mysql_bin = "mysql"
    else:
        # Check QNAP specific path if global isn't found
        qnap_check = subprocess.run(["getcfg", "MariaDB10", "Install_Path", "-f", "/etc/config/qpkg.conf"], capture_output=True, text=True)
        if qnap_check.returncode == 0 and qnap_check.stdout.strip():
            qnap_bin = os.path.join(qnap_check.stdout.strip(), "bin", "mysql")
            if os.path.isfile(qnap_bin) and os.access(qnap_bin, os.X_OK):
                mysql_bin = qnap_bin

    if not mysql_bin:
        print("Error: 'mariadb' or 'mysql' command not found. Make sure MariaDB is installed.")
        return

    # Pass password securely via environment variable
    env = os.environ.copy()
    if password:
        env["MYSQL_PWD"] = password

    # Construct command
    cmd = [mysql_bin, "-u", user, "-e", sql, "-t"]
    if host.startswith("/"):
        cmd.insert(1, f"--socket={host}")
    else:
        cmd.insert(1, "-h")
        cmd.insert(2, host)

    print(f"\n--- Statistics for {db_name} ---")
    try:
        # Capture stderr so we can print the real error if it fails
        result = subprocess.run(cmd, check=True, text=True, capture_output=True, env=env)
        print(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Error: Could not connect to database or query failed.")
        if e.stderr:
            print(f"Details: {e.stderr.strip()}")
        else:
            print("Check your credentials and host/socket path.")
    except FileNotFoundError:
        print("Error: 'mariadb' or 'mysql' command not found.")

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 db_stats.py <host> <user> <db_name>")
        print("Note: DB_PASS must be set as an environment variable.")
        sys.exit(1)

    get_db_stats(sys.argv[1], sys.argv[2], sys.argv[3])

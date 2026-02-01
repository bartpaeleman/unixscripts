import sys
import subprocess
import re

def get_db_stats(host, user, password, db_name):
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

    # Construct command (using mysql CLI to avoid dependencies)
    cmd = ["mysql", "-h", host, "-u", user, f"-p{password}", "-e", sql, "-t"]

    print(f"\n--- Statistics for {db_name} ---")
    try:
        # Suppress password warning
        result = subprocess.run(cmd, check=True, text=True, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        print("Error: Could not connect to database or query failed.")
        print("Check your credentials and host.")
    except FileNotFoundError:
        print("Error: 'mysql' command not found.")

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: python3 db_stats.py <host> <user> <password> <db_name>")
        sys.exit(1)

    get_db_stats(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])

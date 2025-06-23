#!/usr/bin/env python3

import subprocess
import json
import sys

def run_pgmetrics_with_monitoring_queries(zabbix_host):
    """
    Example of how to call pgmetrics to get the new monitoring queries.
    
    IMPORTANT: Must use --format json to get the new monitoring query data!
    """
    
    # FIXED: Added --format json to get new monitoring queries
    cmd = [
        'pgmetrics',
        '--format', 'json',  # <-- This is the key addition!
        '--host', zabbix_host
    ]
    
    try:
        # Run pgmetrics and capture JSON output
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        
        # Parse JSON response
        data = json.loads(result.stdout)
        
        # Now you can access the new monitoring queries!
        print("=== NEW MONITORING QUERIES DATA ===")
        
        # Active Sessions with Wait Events
        if 'active_sessions' in data:
            print(f"\nActive Sessions: {len(data['active_sessions'])} found")
            for session in data['active_sessions']:
                print(f"  PID {session['pid']}: {session['wait_event_type']}/{session['wait_event']} - {session['duration']:.2f}s")
        
        # Replication Status
        if 'replication_status' in data:
            print(f"\nReplication Status: {len(data['replication_status'])} connections")
            for repl in data['replication_status']:
                print(f"  PID {repl['pid']}: {repl['state']} - {repl['application_name']}")
        
        # Wait Event Summary
        if 'wait_event_summary' in data:
            print(f"\nWait Event Summary: {len(data['wait_event_summary'])} types")
            for wait in data['wait_event_summary']:
                print(f"  {wait['wait_event_type']}/{wait['wait_event']}: {wait['sessions']} sessions")
        
        # Blocked Sessions
        if 'blocked_sessions' in data:
            print(f"\nBlocked Sessions: {len(data['blocked_sessions'])} found")
            for blocked in data['blocked_sessions']:
                print(f"  PID {blocked['blocked_pid']} blocked by PIDs: {blocked['blocking_pids']}")
        
        # WAL Receiver Status
        if 'wal_receiver_status' in data:
            wal = data['wal_receiver_status']
            print(f"\nWAL Receiver: PID {wal['pid']} - {wal['status']}")
        
        return data
        
    except subprocess.CalledProcessError as e:
        print(f"Error running pgmetrics: {e}")
        print(f"stderr: {e.stderr}")
        return None
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        print(f"stdout: {result.stdout}")
        return None

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 fixed_python_example.py <zabbix_host>")
        print("Example: python3 fixed_python_example.py psql-infra-eastus-qa")
        sys.exit(1)
    
    zabbix_host = sys.argv[1]
    
    print(f"Running pgmetrics with JSON format for host: {zabbix_host}")
    print("This will include the new monitoring queries!")
    print()
    
    data = run_pgmetrics_with_monitoring_queries(zabbix_host)
    
    if data:
        print("\n=== SUCCESS ===")
        print("The new monitoring queries are now available in the JSON data!")
        print("You can process this data in your Zabbix monitoring script.")
    else:
        print("\n=== FAILED ===")
        print("Could not retrieve monitoring data.")

if __name__ == "__main__":
    main() 
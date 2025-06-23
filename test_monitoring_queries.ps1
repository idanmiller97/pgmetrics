#!/usr/bin/env pwsh

# Test script to validate monitoring queries directly against PostgreSQL
# This helps debug why the monitoring data isn't appearing in pgmetrics output

Write-Host "=== Testing Monitoring Queries Directly ==="
Write-Host ""

Connection parameters
$env:PGSSLMODE = "require"
$env:PGPASSWORD = ""
$hostname = "psql-infra-eastus-qa.postgres.database.azure.com"
$port = "5432"
$user = "postgres"

Write-Host "Testing connection to: $hostname"
Write-Host ""

# Test 1: Basic connection test
Write-Host "1. Testing basic connection..."
$testResult = docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c "SELECT current_database(), version();"
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Connection successful"
} else {
    Write-Host "✗ Connection failed"
    exit 1
}
Write-Host ""

# Test 2: Wait Event Summary Query
Write-Host "2. Testing Wait Event Summary Query..."
$waitEventQuery = @"
SELECT COALESCE(wait_event_type, 'NULL') as wait_event_type, 
       COALESCE(wait_event, 'NULL') as wait_event, 
       COUNT(*) AS sessions
FROM pg_stat_activity
WHERE state IN ('active', 'idle', 'idle in transaction')
GROUP BY wait_event_type, wait_event
ORDER BY COUNT(*) DESC;
"@

docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c $waitEventQuery
Write-Host ""

# Test 3: Active Sessions Query
Write-Host "3. Testing Active Sessions Query..."
$activeSessionsQuery = @"
SELECT pid, 
       COALESCE(wait_event_type, 'NULL') as wait_event_type, 
       COALESCE(wait_event, 'NULL') as wait_event, 
       LEFT(COALESCE(query, ''), 100) as query, 
       state,
       EXTRACT(EPOCH FROM (now() - query_start)) AS duration
FROM pg_stat_activity
WHERE state IN ('active', 'idle', 'idle in transaction') 
AND pid != pg_backend_pid()
ORDER BY duration DESC
LIMIT 10;
"@

docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c $activeSessionsQuery
Write-Host ""

# Test 4: Blocked Sessions Query
Write-Host "4. Testing Blocked Sessions Query..."
$blockedSessionsQuery = @"
SELECT a.pid AS blocked_pid,
       a.wait_event_type,
       a.wait_event,
       LEFT(a.query, 100) AS blocked_query,
       pg_blocking_pids(a.pid) AS blocking_pids
FROM pg_stat_activity AS a
WHERE array_length(pg_blocking_pids(a.pid), 1) > 0
ORDER BY a.pid ASC;
"@

docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c $blockedSessionsQuery
Write-Host ""

# Test 5: Replication Status Query
Write-Host "5. Testing Replication Status Query..."
$replicationQuery = @"
SELECT pid, state, application_name, client_addr, 
       EXTRACT(EPOCH FROM backend_start)::bigint AS backend_start,
       sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication
ORDER BY pid ASC;
"@

docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c $replicationQuery
Write-Host ""

# Test 6: WAL Receiver Status Query
Write-Host "6. Testing WAL Receiver Status Query..."
$walReceiverQuery = @"
SELECT pid, status, receive_start_lsn, receive_start_tli,
       EXTRACT(EPOCH FROM last_msg_send_time)::bigint AS last_msg_send_time,
       EXTRACT(EPOCH FROM last_msg_receipt_time)::bigint AS last_msg_receipt_time,
       latest_end_lsn,
       EXTRACT(EPOCH FROM latest_end_time)::bigint AS latest_end_time,
       slot_name, conninfo
FROM pg_stat_wal_receiver
LIMIT 1;
"@

docker run --rm -e PGSSLMODE=require -e PGPASSWORD=SYEgSPOTBhPpN9c3 postgres:13 psql -h $hostname -p $port -U $user -d postgres -c $walReceiverQuery
Write-Host ""

Write-Host "=== Test Complete ==="
Write-Host "If any of the above queries returned data, then the monitoring queries should work."
Write-Host "If pgmetrics still doesn't show the data, the issue is in the Go code logic." 
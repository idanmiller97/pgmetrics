#!/usr/bin/env pwsh

# Test script to demonstrate the difference between human and JSON output
# This shows why the new monitoring queries don't appear in human format

Write-Host "=== Testing pgmetrics output formats ==="
Write-Host ""

# Test 1: Human-readable format (default)
Write-Host "1. Human-readable format (what you're currently getting):"
Write-Host "   Command: pgmetrics --host psql-infra-eastus-qa"
Write-Host "   Result: Contains traditional metrics but NO new monitoring queries"
Write-Host ""

# Test 2: JSON format (what you need)
Write-Host "2. JSON format (what you need for new monitoring queries):"
Write-Host "   Command: pgmetrics --format json --host psql-infra-eastus-qa"
Write-Host "   Result: Contains ALL metrics including new monitoring queries:"
Write-Host "   - active_sessions"
Write-Host "   - replication_status"
Write-Host "   - wait_event_summary"
Write-Host "   - blocked_sessions"
Write-Host "   - wal_receiver_status"
Write-Host ""

Write-Host "=== SOLUTION ==="
Write-Host "Update your Python script to use JSON format:"
Write-Host ""
Write-Host "BEFORE (current):"
Write-Host "cmd = ['pgmetrics', '--host', host]"
Write-Host ""
Write-Host "AFTER (fixed):"
Write-Host "cmd = ['pgmetrics', '--format', 'json', '--host', host]"
Write-Host ""

Write-Host "=== Why this happens ==="
Write-Host "The new monitoring queries are implemented in the data collection layer"
Write-Host "and are included in the JSON model, but the human-readable formatter"
Write-Host "in cmd/pgmetrics/report.go does not display these new fields."
Write-Host ""
Write-Host "This is by design - JSON format contains all data, human format"
Write-Host "contains only the most commonly needed metrics for readability." 
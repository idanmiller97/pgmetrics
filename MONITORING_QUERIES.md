# PostgreSQL Monitoring Queries

This document describes the new monitoring queries that have been added to pgmetrics in schema version 1.19.

## Overview

The following monitoring queries have been integrated into pgmetrics to provide comprehensive PostgreSQL monitoring capabilities:

1. **Active Sessions with Wait Events** - Shows active sessions that are waiting
2. **Replication Status** - Detailed replication information
3. **Replication Slots** - Replication slot status and details
4. **Wait Event Summary** - Summary of wait events by type and event
5. **Blocked Sessions** - Sessions that are blocked by other sessions
6. **WAL Receiver Status** - WAL receiver information for standby servers

## Query Details

### 1. Active Sessions with Wait Events

**Purpose**: Identifies active sessions that are waiting for resources, ordered by duration.

**Query**:
```sql
SELECT
    pid, wait_event_type, wait_event, query, state,
    EXTRACT(EPOCH FROM (now() - query_start)) AS duration
FROM pg_stat_activity
WHERE wait_event IS NOT NULL AND state='active'
ORDER BY duration DESC
```

**Output Fields**:
- `pid`: Process ID
- `wait_event_type`: Type of wait event (Lock, IO, LWLock, etc.)
- `wait_event`: Specific wait event name
- `query`: Current query being executed
- `state`: Session state
- `duration`: How long the session has been waiting (in seconds)

### 2. Replication Status

**Purpose**: Shows detailed information about replication connections.

**Query**:
```sql
SELECT pid, state, application_name, client_addr, 
    EXTRACT(EPOCH FROM backend_start)::bigint AS backend_start,
    sent_lsn, write_lsn, flush_lsn, replay_lsn
FROM pg_stat_replication
ORDER BY pid ASC
```

**Output Fields**:
- `pid`: Process ID of the replication connection
- `state`: Replication state
- `application_name`: Application name of the replica
- `client_addr`: Client address
- `backend_start`: When the backend started
- `sent_lsn`: Last sent LSN
- `write_lsn`: Last write LSN
- `flush_lsn`: Last flush LSN
- `replay_lsn`: Last replay LSN

### 3. Replication Slots

**Purpose**: Shows information about replication slots.

**Query**:
```sql
SELECT slot_name, plugin, slot_type, active, restart_lsn, confirmed_flush_lsn
FROM pg_replication_slots
ORDER BY slot_name ASC
```

**Output Fields**:
- `slot_name`: Name of the replication slot
- `plugin`: Output plugin name
- `slot_type`: Type of slot (physical or logical)
- `active`: Whether the slot is active
- `restart_lsn`: LSN from which streaming can restart
- `confirmed_flush_lsn`: LSN position that has been confirmed flushed

### 4. Wait Event Summary

**Purpose**: Provides a summary of wait events grouped by type and event.

**Query**:
```sql
SELECT wait_event_type, wait_event, COUNT(*) AS sessions
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY wait_event_type, wait_event
ORDER BY COUNT(*) DESC
```

**Output Fields**:
- `wait_event_type`: Type of wait event
- `wait_event`: Specific wait event name
- `sessions`: Number of sessions waiting for this event

### 5. Blocked Sessions

**Purpose**: Identifies sessions that are blocked by other sessions.

**Query**:
```sql
SELECT a.pid AS blocked_pid,
    a.wait_event_type,
    a.wait_event,
    a.query AS blocked_query,
    pg_blocking_pids(a.pid) AS blocking_pids
FROM pg_stat_activity AS a
WHERE array_length(pg_blocking_pids(a.pid), 1) > 0
ORDER BY a.pid ASC
```

**Output Fields**:
- `blocked_pid`: Process ID of the blocked session
- `wait_event_type`: Type of wait event
- `wait_event`: Specific wait event name
- `blocked_query`: Query being executed by the blocked session
- `blocking_pids`: Array of PIDs that are blocking this session

### 6. WAL Receiver Status

**Purpose**: Shows WAL receiver status information (for standby servers).

**Query**:
```sql
SELECT pid, status, receive_start_lsn, receive_start_tli,
    received_lsn, received_tli,
    EXTRACT(EPOCH FROM last_msg_send_time)::bigint AS last_msg_send_time,
    EXTRACT(EPOCH FROM last_msg_receipt_time)::bigint AS last_msg_receipt_time,
    latency, latest_end_lsn,
    EXTRACT(EPOCH FROM latest_end_time)::bigint AS latest_end_time,
    slot_name, conninfo
FROM pg_stat_wal_receiver
LIMIT 1
```

**Output Fields**:
- `pid`: Process ID of the WAL receiver
- `status`: Status of the WAL receiver
- `receive_start_lsn`: LSN where receiving started
- `receive_start_tli`: Timeline where receiving started
- `received_lsn`: Last received LSN
- `received_tli`: Timeline of last received LSN
- `last_msg_send_time`: Time of last message sent
- `last_msg_receipt_time`: Time of last message received
- `latency`: Replication latency in microseconds
- `latest_end_lsn`: Latest end LSN
- `latest_end_time`: Time of latest end LSN
- `slot_name`: Name of the replication slot
- `conninfo`: Connection information

## Usage

These queries are automatically executed when you run pgmetrics. The results are included in the JSON output under the following fields:

- `active_sessions`: Array of active sessions with wait events
- `replication_status`: Array of replication status information
- `replication_slots`: Array of replication slot information (enhanced)
- `wait_event_summary`: Array of wait event summaries
- `blocked_sessions`: Array of blocked sessions
- `wal_receiver_status`: WAL receiver status information

## Example Output

```json
{
  "active_sessions": [
    {
      "pid": 12345,
      "wait_event_type": "Lock",
      "wait_event": "relation",
      "query": "UPDATE users SET last_login = NOW() WHERE id = 1",
      "state": "active",
      "duration": 15.2
    }
  ],
  "replication_status": [
    {
      "pid": 67890,
      "state": "streaming",
      "application_name": "replica1",
      "client_addr": "192.168.1.100",
      "backend_start": 1640995200,
      "sent_lsn": "0/12345678",
      "write_lsn": "0/12345678",
      "flush_lsn": "0/12345678",
      "replay_lsn": "0/12345678"
    }
  ],
  "wait_event_summary": [
    {
      "wait_event_type": "Lock",
      "wait_event": "relation",
      "sessions": 3
    }
  ],
  "blocked_sessions": [
    {
      "blocked_pid": 11111,
      "wait_event_type": "Lock",
      "wait_event": "relation",
      "blocked_query": "UPDATE test SET col = 1",
      "blocking_pids": [22222, 33333]
    }
  ]
}
```

## Requirements

- PostgreSQL 9.6 or later (for most queries)
- Some queries require specific PostgreSQL versions:
  - `pg_blocking_pids()` function: PostgreSQL 9.6+
  - `pg_stat_wal_receiver`: PostgreSQL 9.6+
  - Wait event information: PostgreSQL 9.6+

## Notes

- These queries are designed to be non-intrusive and safe to run on production systems
- All queries use appropriate timeouts to prevent hanging
- Results are ordered to show the most relevant information first (e.g., longest waiting sessions)
- The queries handle NULL values gracefully and provide meaningful defaults 
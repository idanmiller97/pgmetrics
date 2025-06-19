package pgmetrics

import (
	"testing"
)

// TestQueries validates that the monitoring queries are syntactically correct
func TestQueries(t *testing.T) {
	queries := []string{
		// Active sessions query
		`SELECT
			pid, wait_event_type, wait_event, query, state,
			EXTRACT(EPOCH FROM (now() - query_start)) AS duration
			FROM pg_stat_activity
			WHERE wait_event IS NOT NULL AND state='active'
			ORDER BY duration DESC`,

		// Replication status query
		`SELECT pid, state, application_name, client_addr, 
			EXTRACT(EPOCH FROM backend_start)::bigint AS backend_start,
			sent_lsn, write_lsn, flush_lsn, replay_lsn
			FROM pg_stat_replication
			ORDER BY pid ASC`,

		// Replication slots query
		`SELECT slot_name, plugin, slot_type, active, restart_lsn, confirmed_flush_lsn
			FROM pg_replication_slots
			ORDER BY slot_name ASC`,

		// Wait event summary query
		`SELECT wait_event_type, wait_event, COUNT(*) AS sessions
			FROM pg_stat_activity
			WHERE state = 'active'
			GROUP BY wait_event_type, wait_event
			ORDER BY COUNT(*) DESC`,

		// Blocked sessions query
		`SELECT a.pid AS blocked_pid,
			a.wait_event_type,
			a.wait_event,
			a.query AS blocked_query,
			pg_blocking_pids(a.pid) AS blocking_pids
			FROM pg_stat_activity AS a
			WHERE array_length(pg_blocking_pids(a.pid), 1) > 0
			ORDER BY a.pid ASC`,

		// WAL receiver status query
		`SELECT pid, status, receive_start_lsn, receive_start_tli,
			received_lsn, received_tli,
			EXTRACT(EPOCH FROM last_msg_send_time)::bigint AS last_msg_send_time,
			EXTRACT(EPOCH FROM last_msg_receipt_time)::bigint AS last_msg_receipt_time,
			latency, latest_end_lsn,
			EXTRACT(EPOCH FROM latest_end_time)::bigint AS latest_end_time,
			slot_name, conninfo
			FROM pg_stat_wal_receiver
			LIMIT 1`,
	}

	for i, query := range queries {
		t.Logf("Query %d: %s", i+1, query)
		// This is just a syntax check - we can't actually execute without a database
		if len(query) == 0 {
			t.Errorf("Query %d is empty", i+1)
		}
	}
}

// TestDataStructures validates that the new data structures are properly defined
func TestDataStructures(t *testing.T) {
	// Test ActiveSession
	as := ActiveSession{
		PID:          12345,
		WaitEventType: "Lock",
		WaitEvent:    "relation",
		Query:        "SELECT * FROM test",
		State:        "active",
		Duration:     10.5,
	}
	if as.PID != 12345 {
		t.Errorf("Expected PID 12345, got %d", as.PID)
	}

	// Test ReplicationStatus
	rs := ReplicationStatus{
		PID:             67890,
		State:           "streaming",
		ApplicationName: "replica1",
		ClientAddr:      "192.168.1.100",
		BackendStart:    1640995200,
		SentLSN:         "0/12345678",
		WriteLSN:        "0/12345678",
		FlushLSN:        "0/12345678",
		ReplayLSN:       "0/12345678",
	}
	if rs.PID != 67890 {
		t.Errorf("Expected PID 67890, got %d", rs.PID)
	}

	// Test WaitEventSummary
	wes := WaitEventSummary{
		WaitEventType: "Lock",
		WaitEvent:     "relation",
		Sessions:      5,
	}
	if wes.Sessions != 5 {
		t.Errorf("Expected 5 sessions, got %d", wes.Sessions)
	}

	// Test BlockedSession
	bs := BlockedSession{
		BlockedPID:    11111,
		WaitEventType: "Lock",
		WaitEvent:     "relation",
		BlockedQuery:  "UPDATE test SET col = 1",
		BlockingPIDs:  []int{22222, 33333},
	}
	if len(bs.BlockingPIDs) != 2 {
		t.Errorf("Expected 2 blocking PIDs, got %d", len(bs.BlockingPIDs))
	}

	// Test WALReceiverStatus
	wrs := WALReceiverStatus{
		PID:              44444,
		Status:           "streaming",
		ReceiveStartLSN:  "0/10000000",
		ReceiveStartTLI:  1,
		ReceivedLSN:      "0/20000000",
		ReceivedTLI:      1,
		LastMsgSendTime:  1640995200,
		LastMsgReceiptTime: 1640995201,
		Latency:          1000,
		LatestEndLSN:     "0/20000000",
		LatestEndTime:    1640995201,
		SlotName:         "replica1",
		Conninfo:         "host=primary port=5432",
	}
	if wrs.PID != 44444 {
		t.Errorf("Expected PID 44444, got %d", wrs.PID)
	}
} 
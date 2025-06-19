package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/rapidloop/pgmetrics"
	"github.com/rapidloop/pgmetrics/collector"
)

func main() {
	// Create a default collection configuration
	config := collector.DefaultCollectConfig()
	
	// Set connection parameters (modify as needed)
	config.Host = "localhost"
	config.Port = 5432
	config.User = "postgres"
	config.Password = "your_password"
	config.TimeoutSec = 10

	// Collect metrics from the database
	// Replace "your_database" with your actual database name
	dbnames := []string{"your_database"}
	
	fmt.Println("Collecting PostgreSQL metrics...")
	model := collector.Collect(config, dbnames)

	// Print information about the new monitoring queries
	fmt.Println("\n=== Active Sessions with Wait Events ===")
	if len(model.ActiveSessions) > 0 {
		for _, session := range model.ActiveSessions {
			fmt.Printf("PID: %d, Wait Event: %s/%s, Duration: %.2fs, Query: %s\n",
				session.PID, session.WaitEventType, session.WaitEvent,
				session.Duration, session.Query)
		}
	} else {
		fmt.Println("No active sessions with wait events found.")
	}

	fmt.Println("\n=== Replication Status ===")
	if len(model.ReplicationStatus) > 0 {
		for _, repl := range model.ReplicationStatus {
			fmt.Printf("PID: %d, State: %s, App: %s, Client: %s\n",
				repl.PID, repl.State, repl.ApplicationName, repl.ClientAddr)
			fmt.Printf("  Sent LSN: %s, Write LSN: %s, Flush LSN: %s, Replay LSN: %s\n",
				repl.SentLSN, repl.WriteLSN, repl.FlushLSN, repl.ReplayLSN)
		}
	} else {
		fmt.Println("No replication connections found.")
	}

	fmt.Println("\n=== Replication Slots ===")
	if len(model.ReplicationSlots) > 0 {
		for _, slot := range model.ReplicationSlots {
			fmt.Printf("Slot: %s, Type: %s, Plugin: %s, Active: %t\n",
				slot.SlotName, slot.SlotType, slot.Plugin, slot.Active)
			fmt.Printf("  Restart LSN: %s, Confirmed Flush LSN: %s\n",
				slot.RestartLSN, slot.ConfirmedFlushLSN)
		}
	} else {
		fmt.Println("No replication slots found.")
	}

	fmt.Println("\n=== Wait Event Summary ===")
	if len(model.WaitEventSummary) > 0 {
		for _, summary := range model.WaitEventSummary {
			fmt.Printf("Wait Event: %s/%s, Sessions: %d\n",
				summary.WaitEventType, summary.WaitEvent, summary.Sessions)
		}
	} else {
		fmt.Println("No wait events found.")
	}

	fmt.Println("\n=== Blocked Sessions ===")
	if len(model.BlockedSessions) > 0 {
		for _, blocked := range model.BlockedSessions {
			fmt.Printf("Blocked PID: %d, Wait Event: %s/%s\n",
				blocked.BlockedPID, blocked.WaitEventType, blocked.WaitEvent)
			fmt.Printf("  Query: %s\n", blocked.BlockedQuery)
			fmt.Printf("  Blocking PIDs: %v\n", blocked.BlockingPIDs)
		}
	} else {
		fmt.Println("No blocked sessions found.")
	}

	fmt.Println("\n=== WAL Receiver Status ===")
	if model.WALReceiverStatus != nil {
		wrs := model.WALReceiverStatus
		fmt.Printf("PID: %d, Status: %s, Slot: %s\n",
			wrs.PID, wrs.Status, wrs.SlotName)
		fmt.Printf("  Receive Start LSN: %s, Received LSN: %s\n",
			wrs.ReceiveStartLSN, wrs.ReceivedLSN)
		fmt.Printf("  Latency: %d microseconds\n", wrs.Latency)
	} else {
		fmt.Println("No WAL receiver status found (not a standby server).")
	}

	// Optionally save the full JSON output to a file
	if len(os.Args) > 1 && os.Args[1] == "--save-json" {
		jsonData, err := json.MarshalIndent(model, "", "  ")
		if err != nil {
			log.Fatalf("Failed to marshal JSON: %v", err)
		}
		
		err = os.WriteFile("pgmetrics_output.json", jsonData, 0644)
		if err != nil {
			log.Fatalf("Failed to write JSON file: %v", err)
		}
		fmt.Println("\nFull JSON output saved to pgmetrics_output.json")
	}

	fmt.Println("\n=== Schema Version ===")
	fmt.Printf("Model Schema Version: %s\n", model.Metadata.Version)
	fmt.Printf("Collected at: %d\n", model.Metadata.At)
	fmt.Printf("Collected databases: %v\n", model.Metadata.CollectedDBs)
}

// Example function to extract specific monitoring information
func getLongestWaitingSessions(model *pgmetrics.Model, limit int) []pgmetrics.ActiveSession {
	if len(model.ActiveSessions) == 0 {
		return nil
	}

	// Sort by duration (longest first) and return top N
	sessions := make([]pgmetrics.ActiveSession, len(model.ActiveSessions))
	copy(sessions, model.ActiveSessions)

	// Simple bubble sort for demonstration (use sort.Slice in production)
	for i := 0; i < len(sessions)-1; i++ {
		for j := 0; j < len(sessions)-i-1; j++ {
			if sessions[j].Duration < sessions[j+1].Duration {
				sessions[j], sessions[j+1] = sessions[j+1], sessions[j]
			}
		}
	}

	if limit > len(sessions) {
		limit = len(sessions)
	}
	return sessions[:limit]
}

// Example function to check for replication lag
func checkReplicationLag(model *pgmetrics.Model) {
	if len(model.ReplicationStatus) == 0 {
		fmt.Println("No replication connections found.")
		return
	}

	for _, repl := range model.ReplicationStatus {
		if repl.State == "streaming" {
			// This is a simplified check - in practice you'd compare LSNs
			fmt.Printf("Replication connection %d is streaming\n", repl.PID)
		} else {
			fmt.Printf("Replication connection %d is in state: %s\n", repl.PID, repl.State)
		}
	}
}

// Example function to identify blocking chains
func analyzeBlockingChains(model *pgmetrics.Model) {
	if len(model.BlockedSessions) == 0 {
		fmt.Println("No blocking detected.")
		return
	}

	fmt.Println("Blocking chains detected:")
	for _, blocked := range model.BlockedSessions {
		fmt.Printf("Session %d is blocked by sessions: %v\n",
			blocked.BlockedPID, blocked.BlockingPIDs)
	}
} 
// Package main is the entry point for the ingestion-go service.
package main

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

func main() {
	// Simple health check CLI
	if len(os.Args) > 1 && os.Args[1] == "health" {
		fmt.Println("healthy")
		os.Exit(0)
	}

	http.HandleFunc("/health", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = fmt.Fprintf(w, `{"status": "healthy", "service": "ingestion-go"}`)
	})

	fmt.Println("🚀 Ingestion Go Service starting on port 8080...")
	server := &http.Server{
		Addr:              ":8080",
		ReadHeaderTimeout: 3 * time.Second,
	}
	if err := server.ListenAndServe(); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

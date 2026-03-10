// Package main is the entry point for the ingestion-go service.
package main

import (
	"fmt"
	"time"
)

func main() {
	fmt.Println("🚀 Ingestion Go Service starting...")
	for {
		time.Sleep(1 * time.Hour)
	}
}

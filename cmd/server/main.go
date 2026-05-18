package main

import (
	"log"
	"net/http"
	"os"

	"github.com/kazimc4n/insider_case/internal/handler"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/ping", handler.Ping)
	mux.HandleFunc("/healthz", handler.Healthz)
	mux.HandleFunc("/version", handler.Version)

	log.Printf("Server starting on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}
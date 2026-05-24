package main

import (
	"log"
	"net/http"
	"os"

	"github.com/kazimc4n/insider_case/internal/handler"
)

var version = "dev" // overridden by -ldflags at build time

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/ping", handler.Ping)
	mux.HandleFunc("/healthz", handler.Healthz)
	mux.HandleFunc("/version", handler.MakeVersion(version))

	log.Printf("Server starting on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}
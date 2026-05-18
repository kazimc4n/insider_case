package main

import (
	"flag"
	"log"
	"net/http"
	"os"

	"github.com/kazimc4n/insider_case/internal/handler"
)

func main() {

	healthcheck := flag.Bool("healthcheck", false, "run healthcheck and exit")
	flag.Parse()

	if *healthcheck {
		resp, err := http.Get("http://localhost:8080/healthz")
		if err != nil || resp.StatusCode != http.StatusOK {
			os.Exit(1)
		}
		os.Exit(0)
	}
	
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
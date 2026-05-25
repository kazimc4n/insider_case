package main

import (
	"log"
	"log/slog"
	"net/http"
	"os"

	"github.com/kazimc4n/insider_case/internal/handler"
	"github.com/kazimc4n/insider_case/internal/middleware"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var version = "dev" // overridden by -ldflags at build time

func main() {
	// Initialize structured JSON logging
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/ping", handler.Ping)
	mux.HandleFunc("/healthz", handler.Healthz)
	mux.HandleFunc("/version", handler.MakeVersion(version))

	// Add prometheus metrics endpoint
	mux.Handle("/metrics", promhttp.Handler())

	// Apply middleware: first logger, then metrics
	h := middleware.RequestLogger(middleware.Metrics(mux))

	slog.Info("Server starting", slog.String("port", port))
	if err := http.ListenAndServe(":"+port, h); err != nil {
		log.Fatal(err)
	}
}

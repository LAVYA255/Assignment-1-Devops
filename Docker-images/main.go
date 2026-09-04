package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

const message = "Hello World from Docker multi-stage build"

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprintf(w, `<!doctype html>
<html>
  <head><title>Docker Multi-Stage Build</title></head>
  <body style="font-family: system-ui, sans-serif; text-align: center; padding-top: 80px;">
    <h1>%s</h1>
    <p>This binary was compiled in a Go builder stage and copied into a scratch image.</p>
  </body>
</html>`, message)
	})

	http.HandleFunc("/plain", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, message)
	})

	log.Printf("listening on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

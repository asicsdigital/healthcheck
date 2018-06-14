package main

import (
  "encoding/json"
  "net/http"

  "github.com/thoas/stats"
  "github.com/urfave/negroni"
)

func main() {
  mux := http.NewServeMux()

  // middleware - stats
  middlewareStats := stats.New()
  mux.HandleFunc("/stats", statsHandler(middlewareStats))

  n := negroni.Classic()
  n.UseHandler(mux)

  n.Run()
}

func statsHandler(s *stats.Stats) func(http.ResponseWriter, *http.Request) {
  return func(w http.ResponseWriter, r *http.Request) {
    w.Header().Set("Content-TYpe", "application/json")

    stats := s.Data()

    b, _ := json.Marshal(stats)

    w.Write(b)
  }
}

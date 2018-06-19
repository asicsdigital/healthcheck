package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/caarlos0/env"
	"github.com/urfave/negroni"
)

type config struct {
	Port        int    `env:"PORT"`
	Application string `env:"HEALTHCHECK_APP" envDefault:"healthcheck"`
	Status      int    `env:"HEALTHCHECK_STATUS" envDefault:"200"`
	Metrics     string `env:"HEALTHCHECK_METRICS" envDefault:"{}"`
}

type healthcheck struct {
	Application string `json:"application"`
	Status      int    `json:"status"`
	Metrics     string `json:"metrics"`
}

func main() {
	cfg := config{}
	hc := healthcheck{}

	// default config for our own healthcheck
	defcfg := config{Application: "healthcheck", Status: 200, Metrics: "{}"}

	mux := http.NewServeMux()

	n := negroni.Classic()

	// middleware - config
	n.Use(negroni.HandlerFunc(configHandler(&cfg)))

	// middleware - static file serving
	n.Use(negroni.NewStatic(http.Dir("./static")))

	// middleware - healthcheck (dynamic)
	mux.HandleFunc("/healthcheck", healthcheckHandler(&hc, &cfg))

	// middleware - healthcheck (static)
	mux.HandleFunc("/static-hc", healthcheckHandler(&hc, &defcfg))

	n.UseHandler(mux)

	n.Run()
}

func healthcheckHandler(hc *healthcheck, c *config) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		hc.Application = c.Application
		hc.Status = c.Status
		hc.Metrics = c.Metrics

		b, _ := json.Marshal(*hc)

		w.WriteHeader(hc.Status)
		w.Write(b)
	}
}

func configHandler(c *config) func(http.ResponseWriter, *http.Request, http.HandlerFunc) {
	return func(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
		err := env.Parse(c)

		if err != nil {
			panic(fmt.Sprintf("panic: %s", err))
		}

		next(w, r)
	}
}

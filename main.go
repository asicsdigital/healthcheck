package main

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/caarlos0/env"
	"github.com/urfave/negroni"

  beeline "github.com/honeycombio/beeline-go"
	"github.com/honeycombio/beeline-go/wrappers/hnynethttp"
)

const GitHubURI string = "https://github.com/asicsdigital/healthcheck"
const HealthCheckPath string = "/healthcheck"

type config struct {
	Port         int    `env:"PORT"`
	Application  string `env:"HEALTHCHECK_APP" envDefault:"healthcheck"`
	Status       int    `env:"HEALTHCHECK_STATUS" envDefault:"200"`
	Metrics      string `env:"HEALTHCHECK_METRICS" envDefault:"{}"`
	HoneyKey     string `env:"HONEYCOMB_API_KEY" envDefault:"ce8f58cf494fa93b7376d053c577a894"`
	HoneyDataset string `env:"HONEYCOMB_DATASET" envDefault:"healthcheck"`
}


type healthcheck struct {
	Application string                 `json:"application"`
	Status      int                    `json:"status"`
	Metrics     map[string]interface{} `json:"metrics"`
}

func main() {
	cfg := config{}
  env.Parse(&cfg)

	hc := healthcheck{}

	// default config for our own healthcheck
	defcfg := config{Application: "healthcheck", Status: 200, Metrics: "{}" }

	beeline.Init(beeline.Config{
			WriteKey: cfg.HoneyKey,
			Dataset: cfg.HoneyDataset,
	})
	defer beeline.Close()


	mux := http.NewServeMux()

	n := negroni.Classic()

	// middleware - config
	n.Use(negroni.HandlerFunc(configHandler(&cfg)))

	// middleware - static file serving
	n.Use(negroni.NewStatic(http.Dir("./static")))

	// middleware - healthcheck (dynamic)
	mux.HandleFunc(HealthCheckPath, healthcheckHandler(&hc, &cfg))

	// middleware - healthcheck (static)
	mux.HandleFunc("/static-hc", healthcheckHandler(&hc, &defcfg))

	// middleware - redirect readme to GitHub
	mux.HandleFunc("/readme", redirectHandler(GitHubURI, http.StatusMovedPermanently))

	// middleware - redirect / to /healthcheck
	mux.HandleFunc("/", redirectHandler(HealthCheckPath, http.StatusMovedPermanently))

	n.UseHandler(hnynethttp.WrapHandler(mux))

	n.Run()
}

func redirectHandler(target string, code int) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {

		// redirect if code is 3xx
		if 300 <= code && code < 400 {
			http.Redirect(w, r, target, code)
		} else {
			panic(fmt.Sprintf("provided code %d is not in the 3xx range", code))
		}
	}
}

func healthcheckHandler(hc *healthcheck, c *config) func(http.ResponseWriter, *http.Request) {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		hc.Application = c.Application
		hc.Status = c.Status
		hc.Metrics = parseMetrics(c.Metrics)

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

func parseMetrics(unparsed string) map[string]interface{} {
	var f interface{}
	err := json.Unmarshal([]byte(unparsed), &f)

	if err != nil {
		panic(fmt.Sprintf("%s: %s", err, unparsed))
	}

	parsed := f.(map[string]interface{})

	return parsed
}

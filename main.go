/*
gitlab-workhorse handles slow requests for GitLab

This HTTP server can service 'git clone', 'git push' etc. commands
from Git clients that use the 'smart' Git HTTP protocol (git-upload-pack
and git-receive-pack). It is intended to be deployed behind NGINX
(for request routing and SSL termination) with access to a GitLab
backend (for authentication and authorization) and local disk access
to Git repositories managed by GitLab. In GitLab, this role was previously
performed by gitlab-grack.

In this file we start the web server and hand off to the upstream type.
*/
package main

import (
	"flag"
	"fmt"
	"net"
	"net/http"
	_ "net/http/pprof"
	"os"
	"syscall"
	"time"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/monitoring"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/redis"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upstream"
)

// Version is the current version of GitLab Workhorse
var Version = "(unknown version)" // Set at build time in the Makefile
// BuildTime signifies the time the binary was build
var BuildTime = "19700101.000000" // Set at build time in the Makefile

var printVersion = flag.Bool("version", false, "Print version and exit")
var configFile = flag.String("config", "", "TOML file to load config from")
var listenAddr = flag.String("listenAddr", "localhost:8181", "Listen address for HTTP server")
var listenNetwork = flag.String("listenNetwork", "tcp", "Listen 'network' (tcp, tcp4, tcp6, unix)")
var listenUmask = flag.Int("listenUmask", 0, "Umask for Unix socket")
var authBackend = flag.String("authBackend", upstream.DefaultBackend.String(), "Authentication/authorization backend")
var authSocket = flag.String("authSocket", "", "Optional: Unix domain socket to dial authBackend at")
var pprofListenAddr = flag.String("pprofListenAddr", "", "pprof listening address, e.g. 'localhost:6060'")
var documentRoot = flag.String("documentRoot", "public", "Path to static files content")
var proxyHeadersTimeout = flag.Duration("proxyHeadersTimeout", 5*time.Minute, "How long to wait for response headers when proxying the request")
var developmentMode = flag.Bool("developmentMode", false, "Allow the assets to be served from Rails app")
var secretPath = flag.String("secretPath", "./.gitlab_workhorse_secret", "File with secret key to authenticate with authBackend")
var apiLimit = flag.Uint("apiLimit", 0, "Number of API requests allowed at single time")
var apiQueueLimit = flag.Uint("apiQueueLimit", 0, "Number of API requests allowed to be queued")
var apiQueueTimeout = flag.Duration("apiQueueDuration", queueing.DefaultTimeout, "Maximum queueing duration of requests")
var apiCiLongPollingDuration = flag.Duration("apiCiLongPollingDuration", 50, "Long polling duration for job requesting for runners (default 50s - enabled)")

var prometheusListenAddr = flag.String("prometheusListenAddr", "", "Prometheus listening address, e.g. 'localhost:9229'")

var logConfig = logConfiguration{}

func init() {
	flag.StringVar(&logConfig.logFile, "logFile", "", "Log file location")
	flag.StringVar(&logConfig.logFormat, "logFormat", "text", "Log format to use defaults to text (text, json, structured, none)")
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\n  %s [OPTIONS]\n\nOptions:\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	if *printVersion {
		fmt.Printf("gitlab-workhorse %s-%s\n", Version, BuildTime)
		os.Exit(0)
	}

	closer, err := startLogging(logConfig)
	if err != nil {
		log.WithError(err).Fatal("Unable to configure logger")
	}
	defer closer.Close()

	tracing.Initialize(tracing.WithServiceName("gitlab-workhorse"))

	backendURL, err := parseAuthBackend(*authBackend)
	if err != nil {
		log.WithError(err).Fatal("Invalid authBackend")
	}

	log.WithField("version", Version).WithField("build_time", BuildTime).Print("Starting")

	// Good housekeeping for Unix sockets: unlink before binding
	if *listenNetwork == "unix" {
		if err := os.Remove(*listenAddr); err != nil && !os.IsNotExist(err) {
			log.WithError(err).Fatal("Failed to remove socket")
		}
	}

	// Change the umask only around net.Listen()
	oldUmask := syscall.Umask(*listenUmask)
	listener, err := net.Listen(*listenNetwork, *listenAddr)
	syscall.Umask(oldUmask)
	if err != nil {
		log.WithError(err).Fatal("Failed to listen")
	}

	// The profiler will only be activated by HTTP requests. HTTP
	// requests can only reach the profiler if we start a listener. So by
	// having no profiler HTTP listener by default, the profiler is
	// effectively disabled by default.
	if *pprofListenAddr != "" {
		go func() {
			err := http.ListenAndServe(*pprofListenAddr, nil)
			if err != nil {
				log.WithError(err).Error("Failed to start pprof listener")
			}
		}()
	}

	if *prometheusListenAddr != "" {
		go func() {
			err := monitoring.Serve(
				monitoring.WithListenerAddress(*prometheusListenAddr),
				monitoring.WithBuildInformation(Version, BuildTime),
			)
			if err != nil {
				log.WithError(err).Error("Failed to start prometheus listener")
			}
		}()
	}

	secret.SetPath(*secretPath)
	cfg := config.Config{
		Backend:                  backendURL,
		Socket:                   *authSocket,
		Version:                  Version,
		DocumentRoot:             *documentRoot,
		DevelopmentMode:          *developmentMode,
		ProxyHeadersTimeout:      *proxyHeadersTimeout,
		APILimit:                 *apiLimit,
		APIQueueLimit:            *apiQueueLimit,
		APIQueueTimeout:          *apiQueueTimeout,
		APICILongPollingDuration: *apiCiLongPollingDuration,
	}

	if *configFile != "" {
		cfgFromFile, err := config.LoadConfig(*configFile)
		if err != nil {
			log.WithField("configFile", *configFile).WithError(err).Fatal("Can not load config file")
		}

		cfg.Redis = cfgFromFile.Redis

		if cfg.Redis != nil {
			redis.Configure(cfg.Redis, redis.DefaultDialFunc)
			go redis.Process()
		}
	}

	accessLogger, accessCloser, err := getAccessLogger(logConfig)
	if err != nil {
		log.WithError(err).Fatal("Unable to configure access logger")
	}
	if accessCloser != nil {
		defer accessCloser.Close()
	}

	up := wrapRaven(upstream.NewUpstream(cfg, accessLogger))

	err = http.Serve(listener, up)
	if err != nil {
		log.WithError(err).Fatal("Unable to serve")
	}
}

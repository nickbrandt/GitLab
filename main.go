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
var cableBackend = flag.String("cableBackend", upstream.DefaultBackend.String(), "ActionCable backend")
var cableSocket = flag.String("cableSocket", "", "Optional: Unix domain socket to dial cableBackend at")
var pprofListenAddr = flag.String("pprofListenAddr", "", "pprof listening address, e.g. 'localhost:6060'")
var documentRoot = flag.String("documentRoot", "public", "Path to static files content")
var proxyHeadersTimeout = flag.Duration("proxyHeadersTimeout", 5*time.Minute, "How long to wait for response headers when proxying the request")
var developmentMode = flag.Bool("developmentMode", false, "Allow the assets to be served from Rails app")
var secretPath = flag.String("secretPath", "./.gitlab_workhorse_secret", "File with secret key to authenticate with authBackend")
var apiLimit = flag.Uint("apiLimit", 0, "Number of API requests allowed at single time")
var apiQueueLimit = flag.Uint("apiQueueLimit", 0, "Number of API requests allowed to be queued")
var apiQueueTimeout = flag.Duration("apiQueueDuration", queueing.DefaultTimeout, "Maximum queueing duration of requests")
var apiCiLongPollingDuration = flag.Duration("apiCiLongPollingDuration", 50, "Long polling duration for job requesting for runners (default 50s - enabled)")
var propagateCorrelationID = flag.Bool("propagateCorrelationID", false, "Reuse existing Correlation-ID from the incoming request header `X-Request-ID` if present")

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

	log.WithError(run()).Fatal("shutting down")
}

func run() error {
	closer, err := startLogging(logConfig)
	if err != nil {
		return err
	}
	defer closer.Close()

	tracing.Initialize(tracing.WithServiceName("gitlab-workhorse"))

	backendURL, err := parseAuthBackend(*authBackend)
	if err != nil {
		return fmt.Errorf("authBackend: %v", err)
	}

	cableBackendURL, err := parseAuthBackend(*cableBackend)
	if err != nil {
		return fmt.Errorf("cableBackend: %v", err)
	}

	log.WithField("version", Version).WithField("build_time", BuildTime).Print("Starting")

	// Good housekeeping for Unix sockets: unlink before binding
	if *listenNetwork == "unix" {
		if err := os.Remove(*listenAddr); err != nil && !os.IsNotExist(err) {
			return err
		}
	}

	// Change the umask only around net.Listen()
	oldUmask := syscall.Umask(*listenUmask)
	listener, err := net.Listen(*listenNetwork, *listenAddr)
	syscall.Umask(oldUmask)
	if err != nil {
		return fmt.Errorf("main listener: %v", err)
	}

	finalErrors := make(chan error)

	// The profiler will only be activated by HTTP requests. HTTP
	// requests can only reach the profiler if we start a listener. So by
	// having no profiler HTTP listener by default, the profiler is
	// effectively disabled by default.
	if *pprofListenAddr != "" {
		l, err := net.Listen("tcp", *pprofListenAddr)
		if err != nil {
			return fmt.Errorf("pprofListenAddr: %v", err)
		}

		go func() { finalErrors <- http.Serve(l, nil) }()
	}

	monitoringOpts := []monitoring.Option{monitoring.WithBuildInformation(Version, BuildTime)}

	if *prometheusListenAddr != "" {
		l, err := net.Listen("tcp", *prometheusListenAddr)
		if err != nil {
			return fmt.Errorf("prometheusListenAddr: %v", err)
		}
		monitoringOpts = append(monitoringOpts, monitoring.WithListener(l))
	}
	go func() {
		// Unlike http.Serve, which always returns a non-nil error,
		// monitoring.Start may return nil in which case we should not shut down.
		if err := monitoring.Start(monitoringOpts...); err != nil {
			finalErrors <- err
		}
	}()

	secret.SetPath(*secretPath)
	cfg := config.Config{
		Backend:                  backendURL,
		CableBackend:             cableBackendURL,
		Socket:                   *authSocket,
		CableSocket:              *cableSocket,
		Version:                  Version,
		DocumentRoot:             *documentRoot,
		DevelopmentMode:          *developmentMode,
		ProxyHeadersTimeout:      *proxyHeadersTimeout,
		APILimit:                 *apiLimit,
		APIQueueLimit:            *apiQueueLimit,
		APIQueueTimeout:          *apiQueueTimeout,
		APICILongPollingDuration: *apiCiLongPollingDuration,
		PropagateCorrelationID:   *propagateCorrelationID,
		ImageResizerConfig:       config.DefaultImageResizerConfig,
	}

	if *configFile != "" {
		cfgFromFile, err := config.LoadConfig(*configFile)
		if err != nil {
			return fmt.Errorf("configFile: %v", err)
		}

		cfg.Redis = cfgFromFile.Redis
		cfg.ObjectStorageCredentials = cfgFromFile.ObjectStorageCredentials
		cfg.ImageResizerConfig = cfgFromFile.ImageResizerConfig

		if cfg.Redis != nil {
			redis.Configure(cfg.Redis, redis.DefaultDialFunc)
			go redis.Process()
		}

		err = cfg.RegisterGoCloudURLOpeners()
		if err != nil {
			return fmt.Errorf("register cloud credentials: %v", err)
		}
	}

	accessLogger, accessCloser, err := getAccessLogger(logConfig)
	if err != nil {
		return fmt.Errorf("configure access logger: %v", err)
	}
	defer accessCloser.Close()

	up := wrapRaven(upstream.NewUpstream(cfg, accessLogger))

	go func() { finalErrors <- http.Serve(listener, up) }()

	return <-finalErrors
}

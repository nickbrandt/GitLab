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
	"log"
	"net"
	"net/http"
	_ "net/http/pprof"
	"os"
	"regexp"
	"strings"
	"syscall"
	"time"
)

var Version = "(unknown version)" // Set at build time in the Makefile

var printVersion = flag.Bool("version", false, "Print version and exit")
var listenAddr = flag.String("listenAddr", "localhost:8181", "Listen address for HTTP server")
var listenNetwork = flag.String("listenNetwork", "tcp", "Listen 'network' (tcp, tcp4, tcp6, unix)")
var listenUmask = flag.Int("listenUmask", 022, "Umask for Unix socket, default: 022")
var authBackend = flag.String("authBackend", "http://localhost:8080", "Authentication/authorization backend")
var authSocket = flag.String("authSocket", "", "Optional: Unix domain socket to dial authBackend at")
var pprofListenAddr = flag.String("pprofListenAddr", "", "pprof listening address, e.g. 'localhost:6060'")
var relativeUrlRoot = flag.String("relativeUrlRoot", "/", "GitLab relative URL root")
var documentRoot = flag.String("documentRoot", "public", "Path to static files content")
var deployPage = flag.String("deployPage", "public/index.html", "Path to file that will always be served if present")
var errorPages = flag.String("errorPages", "public/index.html", "The folder containing custom error pages, ie.: 500.html")

type httpRoute struct {
	method     string
	regex      *regexp.Regexp
	handleFunc serviceHandleFunc
}

// Routing table
// We match against URI not containing the relativeUrlRoot:
// see upstream.ServeHTTP
var httpRoutes = [...]httpRoute{
	httpRoute{"GET", regexp.MustCompile(`/info/refs\z`), repoPreAuthorizeHandler(handleGetInfoRefs)},
	httpRoute{"POST", regexp.MustCompile(`/git-upload-pack\z`), repoPreAuthorizeHandler(contentEncodingHandler(handlePostRPC))},
	httpRoute{"POST", regexp.MustCompile(`/git-receive-pack\z`), repoPreAuthorizeHandler(contentEncodingHandler(handlePostRPC))},
	httpRoute{"GET", regexp.MustCompile(`/repository/archive\z`), repoPreAuthorizeHandler(handleGetArchive)},
	httpRoute{"GET", regexp.MustCompile(`/repository/archive.zip\z`), repoPreAuthorizeHandler(handleGetArchive)},
	httpRoute{"GET", regexp.MustCompile(`/repository/archive.tar\z`), repoPreAuthorizeHandler(handleGetArchive)},
	httpRoute{"GET", regexp.MustCompile(`/repository/archive.tar.gz\z`), repoPreAuthorizeHandler(handleGetArchive)},
	httpRoute{"GET", regexp.MustCompile(`/repository/archive.tar.bz2\z`), repoPreAuthorizeHandler(handleGetArchive)},

	// Git LFS
	httpRoute{"PUT", regexp.MustCompile(`/gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`), lfsAuthorizeHandler(handleStoreLfsObject)},

	// CI artifacts
	httpRoute{"POST", regexp.MustCompile(`^/ci/api/v1/builds/[0-9]+/artifacts\z`), artifactsAuthorizeHandler(contentEncodingHandler(handleFileUploads))},

	// Explicitly proxy API
	httpRoute{"", regexp.MustCompile(`^/api/`), proxyRequest},
	httpRoute{"", regexp.MustCompile(`^/ci/api/`), proxyRequest},

	// Serve static files and forward otherwise
	httpRoute{"", nil, handleServeFile(documentRoot,
		handleDeployPage(deployPage,
			handleRailsError(errorPages,
				proxyRequest,
			)))},
}

func main() {
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage of %s:\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "\n  %s [OPTIONS]\n\nOptions:\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	version := fmt.Sprintf("gitlab-workhorse %s", Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if !strings.HasSuffix(*relativeUrlRoot, "/") {
		*relativeUrlRoot += "/"
	}

	log.Printf("Starting %s", version)

	// Good housekeeping for Unix sockets: unlink before binding
	if *listenNetwork == "unix" {
		if err := os.Remove(*listenAddr); err != nil && !os.IsNotExist(err) {
			log.Fatal(err)
		}
	}

	// Change the umask only around net.Listen()
	oldUmask := syscall.Umask(*listenUmask)
	listener, err := net.Listen(*listenNetwork, *listenAddr)
	syscall.Umask(oldUmask)
	if err != nil {
		log.Fatal(err)
	}

	var authTransport http.RoundTripper
	if *authSocket != "" {
		dialer := &net.Dialer{
			// The values below are taken from http.DefaultTransport
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}
		authTransport = &http.Transport{
			Dial: func(_, _ string) (net.Conn, error) {
				return dialer.Dial("unix", *authSocket)
			},
		}
	}

	// The profiler will only be activated by HTTP requests. HTTP
	// requests can only reach the profiler if we start a listener. So by
	// having no profiler HTTP listener by default, the profiler is
	// effectively disabled by default.
	if *pprofListenAddr != "" {
		go func() {
			log.Print(http.ListenAndServe(*pprofListenAddr, nil))
		}()
	}

	// Because net/http/pprof installs itself in the DefaultServeMux
	// we create a fresh one for the Git server.
	serveMux := http.NewServeMux()
	serveMux.Handle(*relativeUrlRoot, newUpstream(*authBackend, authTransport))
	log.Fatal(http.Serve(listener, serveMux))
}

/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package main

import (
	"./internal/api"
	"./internal/errorpage"
	"./internal/git"
	"./internal/proxy"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"regexp"
	"strings"
	"time"
)

type upstream struct {
	API             *api.API
	Proxy           *proxy.Proxy
	authBackend     string
	relativeURLRoot string
	routes          []route
}

type route struct {
	method  string
	regex   *regexp.Regexp
	handler http.Handler
}

const projectPattern = `^/[^/]+/[^/]+/`
const gitProjectPattern = `^/[^/]+/[^/]+\.git/`

const apiPattern = `^/api/`
const projectsAPIPattern = `^/api/v3/projects/[^/]+/`

const ciAPIPattern = `^/ci/api/`

// Routing table
// We match against URI not containing the relativeUrlRoot:
// see upstream.ServeHTTP
var routes []route

func (u *upstream) compileRoutes() {
	u.routes = []route{
		// Git Clone
		route{"GET", regexp.MustCompile(gitProjectPattern + `info/refs\z`), git.GetInfoRefs(u.API)},
		route{"POST", regexp.MustCompile(gitProjectPattern + `git-upload-pack\z`), contentEncodingHandler(git.PostRPC(u.API))},
		route{"POST", regexp.MustCompile(gitProjectPattern + `git-receive-pack\z`), contentEncodingHandler(git.PostRPC(u.API))},
		route{"PUT", regexp.MustCompile(gitProjectPattern + `gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`), lfsAuthorizeHandler(u.API, handleStoreLfsObject(u.Proxy))},

		// Repository Archive
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.zip\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar.gz\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectPattern + `repository/archive.tar.bz2\z`), git.GetArchive(u.API)},

		// Repository Archive API
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.zip\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar.gz\z`), git.GetArchive(u.API)},
		route{"GET", regexp.MustCompile(projectsAPIPattern + `repository/archive.tar.bz2\z`), git.GetArchive(u.API)},

		// CI Artifacts API
		route{"POST", regexp.MustCompile(ciAPIPattern + `v1/builds/[0-9]+/artifacts\z`), contentEncodingHandler(artifactsAuthorizeHandler(u.API, handleFileUploads(u.Proxy)))},

		// Explicitly u.Proxy API requests
		route{"", regexp.MustCompile(apiPattern), u.Proxy},
		route{"", regexp.MustCompile(ciAPIPattern), u.Proxy},

		// Serve assets
		route{"", regexp.MustCompile(`^/assets/`),
			u.handleServeFile(documentRoot, CacheExpireMax,
				handleDevelopmentMode(developmentMode,
					handleDeployPage(documentRoot,
						errorpage.Inject(*documentRoot,
							u.Proxy,
						),
					),
				),
			),
		},

		// Serve static files or forward the requests
		route{"", nil,
			u.handleServeFile(documentRoot, CacheDisabled,
				handleDeployPage(documentRoot,
					errorpage.Inject(*documentRoot,
						u.Proxy,
					),
				),
			),
		},
	}
}

func newUpstream(authBackend string, authSocket string) *upstream {
	parsedURL, err := url.Parse(authBackend)
	if err != nil {
		log.Fatalln(err)
	}

	relativeURLRoot := parsedURL.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}

	// Create Proxy Transport
	authTransport := http.DefaultTransport
	if authSocket != "" {
		dialer := &net.Dialer{
			// The values below are taken from http.DefaultTransport
			Timeout:   30 * time.Second,
			KeepAlive: 30 * time.Second,
		}
		authTransport = &http.Transport{
			Dial: func(_, _ string) (net.Conn, error) {
				return dialer.Dial("unix", authSocket)
			},
			ResponseHeaderTimeout: *responseHeadersTimeout,
		}
	}
	proxyTransport := proxy.NewRoundTripper(authTransport)

	up := &upstream{
		authBackend: authBackend,
		API: &api.API{
			Client:  &http.Client{Transport: proxyTransport},
			URL:     parsedURL,
			Version: Version,
		},
		Proxy:           proxy.NewProxy(parsedURL, proxyTransport, Version),
		relativeURLRoot: relativeURLRoot,
	}
	up.compileRoutes()
	return up
}

func (u *upstream) relativeURIPath(p string) string {
	return cleanURIPath(strings.TrimPrefix(p, u.relativeURLRoot))
}

func (u *upstream) ServeHTTP(ow http.ResponseWriter, r *http.Request) {
	var g route

	w := newLoggingResponseWriter(ow)
	defer w.Log(r)

	// Drop WebSocket connection and CONNECT method
	if r.RequestURI == "*" {
		httpError(&w, r, "Connection upgrade not allowed", http.StatusBadRequest)
		return
	}

	// Disallow connect
	if r.Method == "CONNECT" {
		httpError(&w, r, "CONNECT not allowed", http.StatusBadRequest)
		return
	}

	// Check URL Root
	URIPath := cleanURIPath(r.URL.Path)
	if !strings.HasPrefix(URIPath, u.relativeURLRoot) && URIPath+"/" != u.relativeURLRoot {
		httpError(&w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	// Look for a matching Git service
	foundService := false
	for _, g = range u.routes {
		if g.method != "" && r.Method != g.method {
			continue
		}

		if g.regex == nil || g.regex.MatchString(u.relativeURIPath(URIPath)) {
			foundService = true
			break
		}
	}
	if !foundService {
		// The protocol spec in git/Documentation/technical/http-protocol.txt
		// says we must return 403 if no matching service is found.
		httpError(&w, r, "Forbidden", http.StatusForbidden)
		return
	}

	g.handler.ServeHTTP(&w, r)
}

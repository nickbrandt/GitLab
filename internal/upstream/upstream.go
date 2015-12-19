/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"../api"
	"../proxy"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"path"
	"strings"
	"time"
)

type Upstream struct {
	Version                string
	API                    *api.API
	Proxy                  *proxy.Proxy
	DocumentRoot           string
	DevelopmentMode        bool
	ResponseHeadersTimeout time.Duration
	urlPrefix              urlPrefix
	routes                 []route
}

func New(authBackend string, authSocket string, version string, responseHeadersTimeout time.Duration) *Upstream {
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
			ResponseHeaderTimeout: responseHeadersTimeout,
		}
	}
	proxyTransport := proxy.NewRoundTripper(authTransport)

	up := &Upstream{
		API: &api.API{
			Client:  &http.Client{Transport: proxyTransport},
			URL:     parsedURL,
			Version: version,
		},
		Proxy:     proxy.NewProxy(parsedURL, proxyTransport, version),
		urlPrefix: urlPrefix(relativeURLRoot),
	}
	up.compileRoutes()
	return up
}

func (u *Upstream) ServeHTTP(ow http.ResponseWriter, r *http.Request) {
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
	prefix := u.urlPrefix
	if !prefix.match(URIPath) {
		httpError(&w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	// Look for a matching Git service
	var ro route
	foundService := false
	for _, ro = range u.routes {
		if ro.method != "" && r.Method != ro.method {
			continue
		}

		if ro.regex == nil || ro.regex.MatchString(prefix.strip(URIPath)) {
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

	ro.handler.ServeHTTP(&w, r)
}

func httpError(w http.ResponseWriter, r *http.Request, error string, code int) {
	if r.ProtoAtLeast(1, 1) {
		// Force client to disconnect if we render request error
		w.Header().Set("Connection", "close")
	}

	http.Error(w, error, code)
}

// Borrowed from: net/http/server.go
// Return the canonical path for p, eliminating . and .. elements.
func cleanURIPath(p string) string {
	if p == "" {
		return "/"
	}
	if p[0] != '/' {
		p = "/" + p
	}
	np := path.Clean(p)
	// path.Clean removes trailing slash except for root;
	// put the trailing slash back if necessary.
	if p[len(p)-1] == '/' && np != "/" {
		np += "/"
	}
	return np
}

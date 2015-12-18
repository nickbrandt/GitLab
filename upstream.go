/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package main

import (
	"./internal/api"
	"./internal/proxy"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/url"
	"strings"
	"time"
)

type upstream struct {
	API             *api.API
	Proxy           *proxy.Proxy
	authBackend     string
	relativeURLRoot string
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

	return up
}

func (u *upstream) relativeURIPath(p string) string {
	return cleanURIPath(strings.TrimPrefix(p, u.relativeURLRoot))
}

func (u *upstream) ServeHTTP(ow http.ResponseWriter, r *http.Request) {
	var g httpRoute

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
	for _, g = range httpRoutes {
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

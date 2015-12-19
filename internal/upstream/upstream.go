/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"../api"
	"../helper"
	"../proxy"
	"fmt"
	"net/http"
	"net/url"
	"path"
	"sync"
	"time"
)

var DefaultBackend = helper.URLMustParse("http://localhost:8080")

type Upstream struct {
	Backend               *url.URL
	Version               string
	Socket                string
	DocumentRoot          string
	DevelopmentMode       bool
	ResponseHeaderTimeout time.Duration

	_api             *api.API
	configureAPIOnce sync.Once

	_proxy             *proxy.Proxy
	configureProxyOnce sync.Once

	urlPrefix              urlPrefix
	configureURLPrefixOnce sync.Once

	routes              []route
	configureRoutesOnce sync.Once

	transport              http.RoundTripper
	configureTransportOnce sync.Once
}

func (u *Upstream) Proxy() *proxy.Proxy {
	u.configureProxyOnce.Do(u.configureProxy)
	return u._proxy
}

func (u *Upstream) configureProxy() {
	u._proxy = &proxy.Proxy{URL: u.Backend, Transport: u.Transport(), Version: u.Version}
}

func (u *Upstream) API() *api.API {
	u.configureAPIOnce.Do(u.configureAPI)
	return u._api
}

func (u *Upstream) configureAPI() {
	u._api = &api.API{
		Client:  &http.Client{Transport: u.Transport()},
		URL:     u.Backend,
		Version: u.Version,
	}
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
	prefix := u.URLPrefix()
	if !prefix.match(URIPath) {
		httpError(&w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	// Look for a matching Git service
	var ro route
	foundService := false
	for _, ro = range u.Routes() {
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

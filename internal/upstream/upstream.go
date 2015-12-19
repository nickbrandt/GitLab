/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"../api"
	"../helper"
	"../proxy"
	"../staticpages"
	"../urlprefix"
	"fmt"
	"net/http"
	"net/url"
	"strings"
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

	urlPrefix              urlprefix.Prefix
	configureURLPrefixOnce sync.Once

	routes              []route
	configureRoutesOnce sync.Once

	transport              http.RoundTripper
	configureTransportOnce sync.Once

	_static             *staticpages.Static
	configureStaticOnce sync.Once
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

func (u *Upstream) URLPrefix() urlprefix.Prefix {
	u.configureURLPrefixOnce.Do(u.configureURLPrefix)
	return u.urlPrefix
}

func (u *Upstream) configureURLPrefix() {
	if u.Backend == nil {
		u.Backend = DefaultBackend
	}
	relativeURLRoot := u.Backend.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}
	u.urlPrefix = urlprefix.Prefix(relativeURLRoot)
}

// func (u *Upstream) Static() *static.Static {
// 	u.configureStaticOnce.Do(func() {
// 		u._static = &static.Static{u.DocumentRoot}
// 	})
// 	return u._static
// }

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
	URIPath := urlprefix.CleanURIPath(r.URL.Path)
	prefix := u.URLPrefix()
	if !prefix.Match(URIPath) {
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

		if ro.regex == nil || ro.regex.MatchString(prefix.Strip(URIPath)) {
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

/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package main

import (
	"fmt"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
)

type serviceHandleFunc func(http.ResponseWriter, *http.Request, *apiResponse)

type API struct {
	*http.Client
	*url.URL
}

type upstream struct {
	API             *API
	Proxy           *Proxy
	authBackend     string
	relativeURLRoot string
}

type Proxy struct {
	ReverseProxy *httputil.ReverseProxy
}

type apiResponse struct {
	// GL_ID is an environment variable used by gitlab-shell hooks during 'git
	// push' and 'git pull'
	GL_ID string
	// RepoPath is the full path on disk to the Git repository the request is
	// about
	RepoPath string
	// ArchivePath is the full path where we should find/create a cached copy
	// of a requested archive
	ArchivePath string
	// ArchivePrefix is used to put extracted archive contents in a
	// subdirectory
	ArchivePrefix string
	// CommitId is used do prevent race conditions between the 'time of check'
	// in the GitLab Rails app and the 'time of use' in gitlab-workhorse.
	CommitId string
	// StoreLFSPath is provided by the GitLab Rails application
	// to mark where the tmp file should be placed
	StoreLFSPath string
	// LFS object id
	LfsOid string
	// LFS object size
	LfsSize int64
	// TmpPath is the path where we should store temporary files
	// This is set by authorization middleware
	TempPath string
}

func newProxy(url *url.URL, transport http.RoundTripper) *Proxy {
	// Modify a copy of url
	proxyURL := *url
	proxyURL.Path = ""
	proxy := Proxy{ReverseProxy: httputil.NewSingleHostReverseProxy(&proxyURL)}
	proxy.ReverseProxy.Transport = transport
	return &proxy
}

func newUpstream(authBackend string, authTransport http.RoundTripper) *upstream {
	parsedURL, err := url.Parse(authBackend)
	if err != nil {
		log.Fatalln(err)
	}

	relativeURLRoot := parsedURL.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}

	up := &upstream{
		authBackend:     authBackend,
		API:             &API{Client: &http.Client{Transport: authTransport}, URL: parsedURL},
		Proxy:           newProxy(parsedURL, authTransport),
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

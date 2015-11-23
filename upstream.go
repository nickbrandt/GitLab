/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package main

import (
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
)

type serviceHandleFunc func(w http.ResponseWriter, r *gitRequest)

type upstream struct {
	httpClient  *http.Client
	authBackend string
	httpProxy   *httputil.ReverseProxy
}

type authorizationResponse struct {
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

// A gitRequest is an *http.Request decorated with attributes returned by the
// GitLab Rails application.
type gitRequest struct {
	*http.Request
	authorizationResponse
	u *upstream
}

func newUpstream(authBackend string, authTransport http.RoundTripper) *upstream {
	u, err := url.Parse(authBackend)
	if err != nil {
		log.Fatalln(err)
	}

	up := &upstream{
		authBackend: authBackend,
		httpClient:  &http.Client{Transport: authTransport},
		httpProxy:   httputil.NewSingleHostReverseProxy(u),
	}
	up.httpProxy.Transport = authTransport
	return up
}

func (u *upstream) ServeHTTP(ow http.ResponseWriter, r *http.Request) {
	var g httpRoute

	w := newLoggingResponseWriter(ow)
	defer w.Log(r)

	// Look for a matching Git service
	foundService := false
	for _, g = range httpRoutes {
		if g.method != "" && r.Method != g.method {
			continue
		}

		if g.regex == nil || g.regex.MatchString(r.URL.Path) {
			foundService = true
			break
		}
	}
	if !foundService {
		// The protocol spec in git/Documentation/technical/http-protocol.txt
		// says we must return 403 if no matching service is found.
		http.Error(w, "Forbidden", 403)
		return
	}

	request := gitRequest{
		Request: r,
		u:       u,
	}

	g.handleFunc(w, &request)
}

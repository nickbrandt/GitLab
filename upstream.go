/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package main

import (
	"io"
	"log"
	"net/http"
	"os"
	"path"
	"regexp"
)

type serviceHandleFunc func(w http.ResponseWriter, r *gitRequest)

type upstream struct {
	httpClient  *http.Client
	authBackend string
}

type gitService struct {
	method     string
	regex      *regexp.Regexp
	handleFunc serviceHandleFunc
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
}

// A gitReqest is an *http.Request decorated with attributes returned by the
// GitLab Rails application.
type gitRequest struct {
	*http.Request
	authorizationResponse
	u   *upstream
}

// Routing table
var gitServices = [...]gitService{
	gitService{"GET", regexp.MustCompile(`/info/refs\z`), repoPreAuthorizeHandler(handleGetInfoRefs)},
	gitService{"POST", regexp.MustCompile(`/git-upload-pack\z`), repoPreAuthorizeHandler(handlePostRPC)},
	gitService{"POST", regexp.MustCompile(`/git-receive-pack\z`), repoPreAuthorizeHandler(handlePostRPC)},
	gitService{"GET", regexp.MustCompile(`/repository/archive\z`), repoPreAuthorizeHandler(handleGetArchive)},
	gitService{"GET", regexp.MustCompile(`/repository/archive.zip\z`), repoPreAuthorizeHandler(handleGetArchive)},
	gitService{"GET", regexp.MustCompile(`/repository/archive.tar\z`), repoPreAuthorizeHandler(handleGetArchive)},
	gitService{"GET", regexp.MustCompile(`/repository/archive.tar.gz\z`), repoPreAuthorizeHandler(handleGetArchive)},
	gitService{"GET", regexp.MustCompile(`/repository/archive.tar.bz2\z`), repoPreAuthorizeHandler(handleGetArchive)},
	gitService{"GET", regexp.MustCompile(`/uploads/`), handleSendFile},
}

func newUpstream(authBackend string, authTransport http.RoundTripper) *upstream {
	return &upstream{&http.Client{Transport: authTransport}, authBackend}
}

func (u *upstream) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var g gitService

	log.Printf("%s %q", r.Method, r.URL)

	// Look for a matching Git service
	foundService := false
	for _, g = range gitServices {
		if r.Method == g.method && g.regex.MatchString(r.URL.Path) {
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

func looksLikeRepo(p string) bool {
	// If /path/to/foo.git/objects exists then let's assume it is a valid Git
	// repository.
	if _, err := os.Stat(path.Join(p, "objects")); err != nil {
		log.Print(err)
		return false
	}
	return true
}

func (u *upstream) newUpstreamRequest(r *http.Request, body io.Reader, suffix string) (*http.Request, error) {
	url := u.authBackend + r.URL.RequestURI() + suffix
	authReq, err := http.NewRequest(r.Method, url, body)
	if err != nil {
		return nil, err
	}
	// Forward all headers from our client to the auth backend. This includes
	// HTTP Basic authentication credentials (the 'Authorization' header).
	for k, v := range r.Header {
		authReq.Header[k] = v
	}

	// Clean some headers when issuing a new request without body
	if body == nil {
		authReq.Header.Del("Content-Type")
		authReq.Header.Del("Content-Encoding")
		authReq.Header.Del("Content-Length")
		authReq.Header.Del("Accept-Encoding")
		authReq.Header.Del("Transfer-Encoding")
	}

	// Also forward the Host header, which is excluded from the Header map by the http libary.
	// This allows the Host header received by the backend to be consistent with other
	// requests not going through gitlab-workhorse.
	authReq.Host = r.Host
	// Set a custom header for the request. This can be used in some
	// configurations (Passenger) to solve auth request routing problems.
	authReq.Header.Set("GitLab-Git-HTTP-Server", Version)

	return authReq, nil
}

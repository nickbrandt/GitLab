package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

func preAuthorizeHandler(handleFunc serviceHandleFunc, suffix string) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		authReq, err := r.u.newUpstreamRequest(r.Request, nil, suffix)
		if err != nil {
			fail500(w, fmt.Errorf("preAuthorizeHandler: newUpstreamRequest: %v", err))
			return
		}

		authResponse, err := r.u.httpClient.Do(authReq)
		if err != nil {
			fail500(w, fmt.Errorf("preAuthorizeHandler: do %v: %v", authReq.URL.Path, err))
			return
		}
		defer authResponse.Body.Close()

		if authResponse.StatusCode != 200 {
			// The Git request is not allowed by the backend. Maybe the
			// client needs to send HTTP Basic credentials.  Forward the
			// response from the auth backend to our client. This includes
			// the 'WWW-Authenticate' header that acts as a hint that
			// Basic auth credentials are needed.
			for k, v := range authResponse.Header {
				// Accomodate broken clients that do case-sensitive header lookup
				if k == "Www-Authenticate" {
					w.Header()["WWW-Authenticate"] = v
				} else {
					w.Header()[k] = v
				}
			}
			w.WriteHeader(authResponse.StatusCode)
			io.Copy(w, authResponse.Body)
			return
		}

		// The auth backend validated the client request and told us additional
		// request metadata. We must extract this information from the auth
		// response body.
		if err := json.NewDecoder(authResponse.Body).Decode(&r.authorizationResponse); err != nil {
			fail500(w, fmt.Errorf("preAuthorizeHandler: decode authorization response: %v", err))
			return
		}
		// Don't hog a TCP connection in CLOSE_WAIT, we can already close it now
		authResponse.Body.Close()

		// Negotiate authentication (Kerberos) may need to return a WWW-Authenticate
		// header to the client even in case of success as per RFC4559.
		for k, v := range authResponse.Header {
			// Case-insensitive comparison as per RFC7230
			if strings.EqualFold(k, "WWW-Authenticate") {
				w.Header()[k] = v
			}
		}

		handleFunc(w, r)
	}
}

func repoPreAuthorizeHandler(handleFunc serviceHandleFunc) serviceHandleFunc {
	return preAuthorizeHandler(func(w http.ResponseWriter, r *gitRequest) {
		if r.RepoPath == "" {
			fail500(w, errors.New("repoPreAuthorizeHandler: RepoPath empty"))
			return
		}

		if !looksLikeRepo(r.RepoPath) {
			http.Error(w, "Not Found", 404)
			return
		}

		handleFunc(w, r)
	}, "")
}

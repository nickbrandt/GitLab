package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
)

func (u *upstream) newUpstreamRequest(r *http.Request, body io.Reader, suffix string) (*http.Request, error) {
	url := u.authBackend + "/" + strings.TrimPrefix(r.URL.RequestURI(), u.relativeURLRoot) + suffix
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
		authReq.Header.Del("Content-Disposition")
		authReq.Header.Del("Accept-Encoding")

		// Hop-by-hop headers. These are removed when sent to the backend.
		// http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html
		authReq.Header.Del("Transfer-Encoding")
		authReq.Header.Del("Connection")
		authReq.Header.Del("Keep-Alive")
		authReq.Header.Del("Proxy-Authenticate")
		authReq.Header.Del("Proxy-Authorization")
		authReq.Header.Del("Te")
		authReq.Header.Del("Trailers")
		authReq.Header.Del("Upgrade")
	}

	// Also forward the Host header, which is excluded from the Header map by the http libary.
	// This allows the Host header received by the backend to be consistent with other
	// requests not going through gitlab-workhorse.
	authReq.Host = r.Host
	// Set a custom header for the request. This can be used in some
	// configurations (Passenger) to solve auth request routing problems.
	authReq.Header.Set("Gitlab-Workhorse", Version)

	return authReq, nil
}

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

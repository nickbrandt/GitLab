package main

import (
	"net/http"
)

func headerClone(h http.Header) http.Header {
	h2 := make(http.Header, len(h))
	for k, vv := range h {
		vv2 := make([]string, len(vv))
		copy(vv2, vv)
		h2[k] = vv2
	}
	return h2
}

func proxyRequest(w http.ResponseWriter, r *gitRequest) {
	// Clone request
	req := *r.Request
	req.Header = headerClone(r.Header)

	// Set Workhorse version
	req.Header.Set("Gitlab-Workhorse", Version)
	rw := newSendFileResponseWriter(w, &req)
	defer rw.Flush()
	r.u.httpProxy.ServeHTTP(rw, &req)
}

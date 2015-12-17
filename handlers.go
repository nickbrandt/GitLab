package main

import (
	"compress/gzip"
	"fmt"
	"io"
	"net/http"
)

func contentEncodingHandler(h handleFunc) handleFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var body io.ReadCloser
		var err error

		// The client request body may have been gzipped.
		contentEncoding := r.Header.Get("Content-Encoding")
		switch contentEncoding {
		case "":
			body = r.Body
		case "gzip":
			body, err = gzip.NewReader(r.Body)
		default:
			err = fmt.Errorf("unsupported content encoding: %s", contentEncoding)
		}

		if err != nil {
			fail500(w, fmt.Errorf("contentEncodingHandler: %v", err))
			return
		}
		defer body.Close()

		r.Body = body
		r.Header.Del("Content-Encoding")

		h(w, r)
	}
}

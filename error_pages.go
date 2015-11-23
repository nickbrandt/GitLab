package main

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"log"
)

type errorPageResponseWriter struct {
	rw       http.ResponseWriter
	status   int
	hijacked bool
}

func newErrorPageResponseWriter(rw http.ResponseWriter) *errorPageResponseWriter {
	s := &errorPageResponseWriter{
		rw: rw,
	}
	return s
}

func (s *errorPageResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *errorPageResponseWriter) Write(data []byte) (n int, err error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return 0, nil
	}
	return s.rw.Write(data)
}

func (s *errorPageResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}

	s.status = status

	switch s.status {
	case 404, 422, 500, 502:
		data, err := ioutil.ReadFile(fmt.Sprintf("public/%d.html", s.status))
		if err != nil {
			break
		}

		log.Printf("ErroPage: serving predefined error page: %d", s.status)
		s.hijacked = true
		s.rw.Header().Set("Content-Type", "text/html")
		s.rw.WriteHeader(s.status)
		s.rw.Write(data)
		return

	default:
		break
	}

	s.rw.WriteHeader(status)
}

func (s *errorPageResponseWriter) Flush() {
	s.WriteHeader(http.StatusOK)
}

func handleRailsError(handler serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		rw := newErrorPageResponseWriter(w)
		defer rw.Flush()
		handler(rw, r)
	}
}

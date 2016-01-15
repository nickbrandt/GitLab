/*
The xSendFile middleware transparently sends static files in HTTP responses
via the X-Sendfile mechanism. All that is needed in the Rails code is the
'send_file' method.
*/

package proxy

import (
	"../helper"
	"log"
	"net/http"
)

type sendFileResponseWriter struct {
	rw       http.ResponseWriter
	status   int
	hijacked bool
	req      *http.Request
}

func newSendFileResponseWriter(rw http.ResponseWriter, req *http.Request) sendFileResponseWriter {
	s := sendFileResponseWriter{
		rw:  rw,
		req: req,
	}
	req.Header.Set("X-Sendfile-Type", "X-Sendfile")
	return s
}

func (s *sendFileResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *sendFileResponseWriter) Write(data []byte) (n int, err error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return
	}
	return s.rw.Write(data)
}

func (s *sendFileResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}

	s.status = status

	// Check X-Sendfile header
	file := s.Header().Get("X-Sendfile")
	s.Header().Del("X-Sendfile")

	// If file is empty or status is not 200 pass through header
	if file == "" || s.status != http.StatusOK {
		s.rw.WriteHeader(s.status)
		return
	}

	// Mark this connection as hijacked
	s.hijacked = true

	// Serve the file
	log.Printf("Send file %q for %s %q", file, s.req.Method, s.req.RequestURI)
	content, fi, err := helper.OpenFile(file)
	if err != nil {
		http.NotFound(s.rw, s.req)
		return
	}
	defer content.Close()

	http.ServeContent(s.rw, s.req, "", fi.ModTime(), content)
}

func (s *sendFileResponseWriter) Flush() {
	s.WriteHeader(http.StatusOK)
}

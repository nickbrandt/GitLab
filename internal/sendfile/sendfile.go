/*
The xSendFile middleware transparently sends static files in HTTP responses
via the X-Sendfile mechanism. All that is needed in the Rails code is the
'send_file' method.
*/

package sendfile

import (
	"log"
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

const sendFileResponseHeader = "X-Sendfile"

type sendFileResponseWriter struct {
	rw       http.ResponseWriter
	status   int
	hijacked bool
	req      *http.Request
}

func SendFile(h http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		s := &sendFileResponseWriter{
			rw:  rw,
			req: req,
		}
		// Advertise to upstream (Rails) that we support X-Sendfile
		req.Header.Set("X-Sendfile-Type", "X-Sendfile")
		defer s.Flush()
		h.ServeHTTP(s, req)
	})
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
	if s.status != http.StatusOK {
		s.rw.WriteHeader(s.status)
		return
	}

	if file := s.Header().Get(sendFileResponseHeader); file != "" {
		s.Header().Del(sendFileResponseHeader)
		// Mark this connection as hijacked
		s.hijacked = true

		// Serve the file
		helper.DisableResponseBuffering(s.rw)
		sendFileFromDisk(s.rw, s.req, file)
		return
	}

	s.rw.WriteHeader(s.status)
	return
}

func sendFileFromDisk(w http.ResponseWriter, r *http.Request, file string) {
	log.Printf("Send file %q for %s %q", file, r.Method, r.RequestURI)
	content, fi, err := helper.OpenFile(file)
	if err != nil {
		http.NotFound(w, r)
		return
	}
	defer content.Close()

	http.ServeContent(w, r, "", fi.ModTime(), content)
}

func (s *sendFileResponseWriter) Flush() {
	s.WriteHeader(http.StatusOK)
}

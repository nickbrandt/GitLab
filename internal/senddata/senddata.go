package senddata

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

type sendDataResponseWriter struct {
	rw        http.ResponseWriter
	status    int
	hijacked  bool
	req       *http.Request
	injecters []Injecter
}

func SendData(h http.Handler, injecters ...Injecter) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s := sendDataResponseWriter{
			rw:        w,
			req:       r,
			injecters: injecters,
		}
		defer s.Flush()
		h.ServeHTTP(&s, r)
	})
}

func (s *sendDataResponseWriter) Header() http.Header {
	return s.rw.Header()
}

func (s *sendDataResponseWriter) Write(data []byte) (n int, err error) {
	if s.status == 0 {
		s.WriteHeader(http.StatusOK)
	}
	if s.hijacked {
		return
	}
	return s.rw.Write(data)
}

func (s *sendDataResponseWriter) WriteHeader(status int) {
	if s.status != 0 {
		return
	}
	s.status = status

	if s.status == http.StatusOK && s.tryInject() {
		return
	}

	s.Header().Del(HeaderKey)
	s.rw.WriteHeader(s.status)
}

func (s *sendDataResponseWriter) tryInject() bool {
	header := s.Header().Get(HeaderKey)
	s.Header().Del(HeaderKey)
	if header == "" {
		return false
	}

	for _, injecter := range s.injecters {
		if injecter.Match(header) {
			s.hijacked = true
			helper.DisableResponseBuffering(s.rw)
			injecter.Inject(s.rw, s.req, header)
			return true
		}
	}

	return false
}

func (s *sendDataResponseWriter) Flush() {
	s.WriteHeader(http.StatusOK)
}

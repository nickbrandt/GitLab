package senddata

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHeaderDelete(t *testing.T) {
	for _, code := range []int{200, 400} {
		recorder := httptest.NewRecorder()
		rw := &sendDataResponseWriter{rw: recorder, req: &http.Request{}}
		rw.Header().Set(HeaderKey, "foobar")
		rw.WriteHeader(code)

		if header := recorder.Header().Get(HeaderKey); header != "" {
			t.Fatalf("HTTP %d response: expected header to be empty, found %q", code, header)
		}
	}
}

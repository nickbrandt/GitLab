package helper

import (
	"log"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
)

func AssertResponseCode(t *testing.T, response *httptest.ResponseRecorder, expectedCode int) {
	if response.Code != expectedCode {
		t.Fatalf("for HTTP request expected to get %d, got %d instead", expectedCode, response.Code)
	}
}

func AssertResponseBody(t *testing.T, response *httptest.ResponseRecorder, expectedBody string) {
	if response.Body.String() != expectedBody {
		t.Fatalf("for HTTP request expected to receive %q, got %q instead as body", expectedBody, response.Body.String())
	}
}

func AssertResponseHeader(t *testing.T, response *httptest.ResponseRecorder, header string, expectedValue string) {
	if response.Header().Get(header) != expectedValue {
		t.Fatalf("for HTTP request expected to receive the header %q with %q, got %q", header, expectedValue, response.Header().Get(header))
	}
}

func TestServerWithHandler(url *regexp.Regexp, handler http.HandlerFunc) *httptest.Server {
	return httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if url != nil && !url.MatchString(r.URL.Path) {
			log.Println("UPSTREAM", r.Method, r.URL, "DENY")
			w.WriteHeader(404)
			return
		}

		if version := r.Header.Get("Gitlab-Workhorse"); version == "" {
			log.Println("UPSTREAM", r.Method, r.URL, "DENY")
			w.WriteHeader(403)
			return
		}

		handler(w, r)
	}))
}

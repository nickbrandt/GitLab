package upstream

import (
	"bytes"
	"compress/gzip"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"reflect"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func TestGzipEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	var b bytes.Buffer
	w := gzip.NewWriter(&b)
	fmt.Fprint(w, "test")
	w.Close()

	body := ioutil.NopCloser(&b)

	req, err := http.NewRequest("POST", "http://address/test", body)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Encoding", "gzip")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		if _, ok := r.Body.(*gzip.Reader); !ok {
			t.Fatal("Expected gzip reader for body, but it's:", reflect.TypeOf(r.Body))
		}
		if r.Header.Get("Content-Encoding") != "" {
			t.Fatal("Content-Encoding should be deleted")
		}
	})).ServeHTTP(resp, req)

	testhelper.RequireResponseCode(t, resp, 200)
}

func TestNoEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	var b bytes.Buffer
	body := ioutil.NopCloser(&b)

	req, err := http.NewRequest("POST", "http://address/test", body)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Encoding", "")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		if r.Body != body {
			t.Fatal("Expected the same body")
		}
		if r.Header.Get("Content-Encoding") != "" {
			t.Fatal("Content-Encoding should be deleted")
		}
	})).ServeHTTP(resp, req)

	testhelper.RequireResponseCode(t, resp, 200)
}

func TestInvalidEncoding(t *testing.T) {
	resp := httptest.NewRecorder()

	req, err := http.NewRequest("POST", "http://address/test", nil)
	if err != nil {
		t.Fatal(err)
	}
	req.Header.Set("Content-Encoding", "application/unknown")

	contentEncodingHandler(http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		t.Fatal("it shouldn't be executed")
	})).ServeHTTP(resp, req)

	testhelper.RequireResponseCode(t, resp, 500)
}

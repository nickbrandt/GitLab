package main

import (
	"bytes"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
)

func TestProxyRequest(t *testing.T) {
	ts := testServerWithHandler(regexp.MustCompile(`/url/path\z`), func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "POST" {
			t.Fatal("Expected POST request")
		}

		if r.Header.Get("Custom-Header") != "test" {
			t.Fatal("Missing custom header")
		}

		var body bytes.Buffer
		io.Copy(&body, r.Body)
		if body.String() != "REQUEST" {
			t.Fatal("Expected REQUEST in request body")
		}

		w.Header().Set("Custom-Response-Header", "test")
		w.WriteHeader(202)
		fmt.Fprint(w, "RESPONSE")
	})

	httpRequest, err := http.NewRequest("POST", ts.URL+"/url/path", bytes.NewBufferString("REQUEST"))
	if err != nil {
		t.Fatal(err)
	}
	httpRequest.Header.Set("Custom-Header", "test")

	request := gitRequest{
		Request: httpRequest,
		u:       newUpstream(ts.URL, nil),
	}

	response := httptest.NewRecorder()
	proxyRequest(response, &request)
	assertResponseCode(t, response, 202)

	if response.Body.String() != "RESPONSE" {
		t.Fatal("Expected RESPONSE in response body:", response.Body.String())
	}

	if response.Header().Get("Custom-Response-Header") != "test" {
		t.Fatal("Expected custom response header")
	}
}

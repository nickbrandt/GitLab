package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
)

func okHandler(w http.ResponseWriter, r *gitRequest) {
	w.WriteHeader(201)
	fmt.Fprint(w, "{\"status\":\"ok\"}")
}

func runPreAuthorizeHandler(t *testing.T, suffix string, url *regexp.Regexp, authorizationResponse interface{}, returnCode, expectedCode int) *httptest.ResponseRecorder {
	// Prepare test server and backend
	ts := testAuthServer(url, returnCode, authorizationResponse)
	defer ts.Close()

	// Create http request
	httpRequest, err := http.NewRequest("GET", "/address", nil)
	if err != nil {
		t.Fatal(err)
	}
	u := newUpstream(ts.URL, nil)
	request := gitRequest{
		Request: httpRequest,
	}

	response := httptest.NewRecorder()
	u.preAuthorizeHandler(okHandler, suffix)(response, &request)
	assertResponseCode(t, response, expectedCode)
	return response
}

func TestPreAuthorizeHappyPath(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		&authorizationResponse{},
		200, 201)
}

func TestPreAuthorizeSuffix(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/different-authorize",
		regexp.MustCompile(`/authorize\z`),
		&authorizationResponse{},
		200, 404)
}

func TestPreAuthorizeJsonFailure(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"not-json",
		200, 500)
}

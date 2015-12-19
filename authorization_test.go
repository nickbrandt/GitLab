package main

import (
	"./internal/api"
	"./internal/helper"
	"./internal/upstream"
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"
	"time"
)

func okHandler(w http.ResponseWriter, _ *http.Request, _ *api.Response) {
	w.WriteHeader(201)
	fmt.Fprint(w, "{\"status\":\"ok\"}")
}

func runPreAuthorizeHandler(t *testing.T, suffix string, url *regexp.Regexp, apiResponse interface{}, returnCode, expectedCode int) *httptest.ResponseRecorder {
	// Prepare test server and backend
	ts := testAuthServer(url, returnCode, apiResponse)
	defer ts.Close()

	// Create http request
	httpRequest, err := http.NewRequest("GET", "/address", nil)
	if err != nil {
		t.Fatal(err)
	}
	api := upstream.New(helper.URLMustParse(ts.URL), "", "123", time.Second).API

	response := httptest.NewRecorder()
	api.PreAuthorizeHandler(okHandler, suffix)(response, httpRequest)
	helper.AssertResponseCode(t, response, expectedCode)
	return response
}

func TestPreAuthorizeHappyPath(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 201)
}

func TestPreAuthorizeSuffix(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/different-authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 404)
}

func TestPreAuthorizeJsonFailure(t *testing.T) {
	runPreAuthorizeHandler(
		t, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"not-json",
		200, 500)
}

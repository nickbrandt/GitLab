package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func okHandler(w http.ResponseWriter, _ *http.Request, _ *api.Response) {
	w.WriteHeader(201)
	fmt.Fprint(w, "{\"status\":\"ok\"}")
}

func runPreAuthorizeHandler(t *testing.T, ts *httptest.Server, suffix string, url *regexp.Regexp, apiResponse interface{}, returnCode, expectedCode int) *httptest.ResponseRecorder {
	if ts == nil {
		ts = testAuthServer(url, returnCode, apiResponse)
		defer ts.Close()
	}

	// Create http request
	httpRequest, err := http.NewRequest("GET", "/address", nil)
	if err != nil {
		t.Fatal(err)
	}
	parsedURL := helper.URLMustParse(ts.URL)
	a := api.NewAPI(parsedURL, "123", testhelper.SecretFile(), badgateway.TestRoundTripper(parsedURL))

	response := httptest.NewRecorder()
	a.PreAuthorizeHandler(okHandler, suffix).ServeHTTP(response, httpRequest)
	testhelper.AssertResponseCode(t, response, expectedCode)
	return response
}

func TestPreAuthorizeHappyPath(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 201)
}

func TestPreAuthorizeSuffix(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/different-authorize",
		regexp.MustCompile(`/authorize\z`),
		&api.Response{},
		200, 404)
}

func TestPreAuthorizeJsonFailure(t *testing.T) {
	runPreAuthorizeHandler(
		t, nil, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"not-json",
		200, 500)
}

func TestPreAuthorizeContentTypeFailure(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, err := w.Write([]byte(`{"hello":"world"}`)); err != nil {
			t.Fatalf("write auth response: %v", err)
		}
	}))
	defer ts.Close()

	runPreAuthorizeHandler(
		t, ts, "/authorize",
		regexp.MustCompile(`/authorize\z`),
		"",
		200, 500)
}

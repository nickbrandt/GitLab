package main

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"regexp"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
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
	a := api.NewAPI(helper.URLMustParse(ts.URL), "123", nil)

	response := httptest.NewRecorder()
	a.PreAuthorizeHandler(okHandler, suffix).ServeHTTP(response, httpRequest)
	testhelper.AssertResponseCode(t, response, expectedCode)
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

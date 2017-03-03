package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func startWorkhorseServerWithLongPolling(authBackend string, pollingDuration time.Duration) *httptest.Server {
	uc := newUpstreamConfig(authBackend)
	uc.APICILongPollingDuration = pollingDuration
	return startWorkhorseServerWithConfig(uc)
}

func postBuildsRegister(url string, body io.Reader) (*http.Response, error) {
	resource := `/ci/api/v1/builds/register.json`
	return http.Post(url+resource, `application/json`, body)
}

func TestBuildsLongPullingEndpointDisabled(t *testing.T) {
	ws := startWorkhorseServerWithLongPolling("http://localhost/", 0)
	defer ws.Close()

	resp, err := postBuildsRegister(ws.URL, nil)
	assert.NoError(t, err)
	defer resp.Body.Close()

	assert.NotEqual(t, "yes", resp.Header.Get("Gitlab-Ci-Builds-Polling"))
}

func TestBuildsLongPullingEndpoint(t *testing.T) {
	ws := startWorkhorseServerWithLongPolling("http://localhost/", time.Minute)
	defer ws.Close()

	resp, err := postBuildsRegister(ws.URL, nil)
	assert.NoError(t, err)
	defer resp.Body.Close()

	assert.Equal(t, "yes", resp.Header.Get("Gitlab-Ci-Builds-Polling"))
}

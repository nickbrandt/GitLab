package builds

import (
	"bytes"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/redis"
)

func echoRequest(rw http.ResponseWriter, req *http.Request) {
	io.Copy(rw, req.Body)
}

var echoRequestFunc = http.HandlerFunc(echoRequest)

const applicationJson = "application/json"

func expectHandlerWithWatcher(t *testing.T, watchHandler WatchKeyHandler, data string, contentType string, expectedHttpStatus int, msgAndArgs ...interface{}) {
	h := RegisterHandler(echoRequestFunc, watchHandler, time.Second)

	rw := httptest.NewRecorder()
	req, _ := http.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", contentType)

	h.ServeHTTP(rw, req)

	assert.Equal(t, expectedHttpStatus, rw.Code, msgAndArgs...)
}

func expectHandler(t *testing.T, data string, contentType string, expectedHttpStatus int, msgAndArgs ...interface{}) {
	expectHandlerWithWatcher(t, nil, data, contentType, expectedHttpStatus, msgAndArgs...)
}

func TestRegisterHandlerLargeBody(t *testing.T) {
	data := strings.Repeat(".", maxRegisterBodySize+5)
	expectHandler(t, data, applicationJson, http.StatusRequestEntityTooLarge,
		"rejects body with entity too large")
}

func TestRegisterHandlerInvalidRunnerRequest(t *testing.T) {
	expectHandler(t, "invalid content", "text/plain", http.StatusOK,
		"proxies request to upstream")
}

func TestRegisterHandlerInvalidJsonPayload(t *testing.T) {
	expectHandler(t, "{[", applicationJson, http.StatusOK,
		"fails on parsing body and proxies request to upstream")
}

func TestRegisterHandlerMissingData(t *testing.T) {
	dataList := []string{"{\"token\":\"token\"}", "{\"last_update\":\"data\"}"}

	for _, data := range dataList {
		expectHandler(t, data, applicationJson, http.StatusOK,
			"fails on argument validation and proxies request to upstream")
	}
}

func exceptWatcherToBeExecuted(t *testing.T, watchKeyStatus redis.WatchKeyStatus, watchKeyError error,
	httpStatus int, msgAndArgs ...interface{}) {
	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		executed = true
		return watchKeyStatus, watchKeyError
	}

	parsableData := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	expectHandlerWithWatcher(t, watchKeyHandler, parsableData, applicationJson, httpStatus, msgAndArgs...)
	assert.True(t, executed, msgAndArgs...)
}

func TestRegisterHandlerWatcherError(t *testing.T) {
	exceptWatcherToBeExecuted(t, redis.WatchKeyStatusNoChange, errors.New("redis connection"),
		http.StatusOK, "proxies data to upstream")
}

func TestRegisterHandlerWatcherAlreadyChanged(t *testing.T) {
	exceptWatcherToBeExecuted(t, redis.WatchKeyStatusAlreadyChanged, nil,
		http.StatusOK, "proxies data to upstream")
}

func TestRegisterHandlerWatcherSeenChange(t *testing.T) {
	exceptWatcherToBeExecuted(t, redis.WatchKeyStatusSeenChange, nil,
		http.StatusNoContent)
}

func TestRegisterHandlerWatcherTimeout(t *testing.T) {
	exceptWatcherToBeExecuted(t, redis.WatchKeyStatusTimeout, nil,
		http.StatusNoContent)
}

func TestRegisterHandlerWatcherNoChange(t *testing.T) {
	exceptWatcherToBeExecuted(t, redis.WatchKeyStatusNoChange, nil,
		http.StatusNoContent)
}

package builds

import (
	"bytes"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"errors"
	"github.com/stretchr/testify/assert"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/redis"
)

func echoRequest(rw http.ResponseWriter, req *http.Request) {
	io.Copy(rw, req.Body)
}

var echoRequestFunc = http.HandlerFunc(echoRequest)

func TestRegisterHandlerLargeBody(t *testing.T) {
	h := RegisterHandler(echoRequestFunc, nil, time.Second)

	data := make([]byte, maxRegisterBodySize+5)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBuffer(data))

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusInternalServerError, rw.Code)
}

func TestRegisterHandlerInvalidRunnerRequest(t *testing.T) {
	h := RegisterHandler(echoRequestFunc, nil, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString("invalid"))

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusOK, rw.Code)
	assert.Equal(t, "invalid", rw.Body.String())
}

func TestRegisterHandlerInvalidJsonPayload(t *testing.T) {
	h := RegisterHandler(echoRequestFunc, nil, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString("{["))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusOK, rw.Code)
	assert.Equal(t, "{[", rw.Body.String())
}

func TestRegisterHandlerMissingData(t *testing.T) {
	datas := []string{"{\"token\":\"token\"}", "{\"last_update\":\"data\"}"}

	for _, data := range datas {
		h := RegisterHandler(echoRequestFunc, nil, time.Second)

		rw := httptest.NewRecorder()
		req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
		req.Header.Set("Content-Type", "application/json")

		h.ServeHTTP(rw, req)

		assert.Equal(t, http.StatusOK, rw.Code)
		assert.Equal(t, data, rw.Body.String())
	}
}

func TestRegisterHandlerWatcherError(t *testing.T) {
	data := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		executed = true
		return redis.WatchKeyStatusNoChange, errors.New("redis connection")
	}

	h := RegisterHandler(echoRequestFunc, watchKeyHandler, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusInternalServerError, rw.Code)
	assert.True(t, executed)
}

func TestRegisterHandlerWatcherAlreadyChanged(t *testing.T) {
	data := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		assert.Equal(t, "runner:build_queue:token", key)
		assert.Equal(t, "last_update", value)
		executed = true
		return redis.WatchKeyStatusAlreadyChanged, nil
	}

	h := RegisterHandler(echoRequestFunc, watchKeyHandler, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusOK, rw.Code)
	assert.Equal(t, data, rw.Body.String())
	assert.True(t, executed)
}

func TestRegisterHandlerWatcherSeenChange(t *testing.T) {
	data := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		assert.Equal(t, "runner:build_queue:token", key)
		assert.Equal(t, "last_update", value)
		executed = true
		return redis.WatchKeyStatusSeenChange, nil
	}

	h := RegisterHandler(echoRequestFunc, watchKeyHandler, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusNoContent, rw.Code)
	assert.True(t, executed)
}

func TestRegisterHandlerWatcherTimeout(t *testing.T) {
	data := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		assert.Equal(t, "runner:build_queue:token", key)
		assert.Equal(t, "last_update", value)
		executed = true
		return redis.WatchKeyStatusTimeout, nil
	}

	h := RegisterHandler(echoRequestFunc, watchKeyHandler, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusNoContent, rw.Code)
	assert.True(t, executed)
}

func TestRegisterHandlerWatcherNoChange(t *testing.T) {
	data := "{\"token\":\"token\",\"last_update\":\"last_update\"}"

	executed := false
	watchKeyHandler := func(key, value string, timeout time.Duration) (redis.WatchKeyStatus, error) {
		assert.Equal(t, "runner:build_queue:token", key)
		assert.Equal(t, "last_update", value)
		executed = true
		return redis.WatchKeyStatusNoChange, nil
	}

	h := RegisterHandler(echoRequestFunc, watchKeyHandler, time.Second)

	rw := httptest.NewRecorder()
	req := httptest.NewRequest("POST", "/", bytes.NewBufferString(data))
	req.Header.Set("Content-Type", "application/json")

	h.ServeHTTP(rw, req)

	assert.Equal(t, http.StatusNoContent, rw.Code)
	assert.True(t, executed)
}

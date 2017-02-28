package builds

import (
	"bytes"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/redis"
	"io"
	"io/ioutil"
	"net/http"
	"time"
)

const MaxRegisterBodySize = 4 * 1024

func readRunnerQueueKey(w http.ResponseWriter, r *http.Request) (string, error) {
	limitedBody := http.MaxBytesReader(w, r.Body, MaxRegisterBodySize)
	defer limitedBody.Close()

	// Read body
	var body bytes.Buffer
	_, err := io.Copy(&body, limitedBody)
	if err != nil {
		return "", err
	}

	r.Body = ioutil.NopCloser(&body)

	tmpReq := *r
	tmpReq.Body = ioutil.NopCloser(bytes.NewReader(body.Bytes()))

	err = tmpReq.ParseForm()
	if err != nil {
		return "", err
	}

	token := tmpReq.FormValue("token")
	if token == "" {
		return "", nil
	}

	key := "runner:build_queue:" + token
	return key, nil
}

func RegisterHandler(h http.Handler, pollingDuration time.Duration) http.Handler {
	if pollingDuration == 0 {
		return h
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lastUpdate := r.Header.Get("X-GitLab-Last-Update")
		if lastUpdate == "" {
			// We could have a fail-over implementation here, for old runners, that:
			// Proxies the requests, if this is 204, we delay the response to client,
			// By checking the response from handler, and reading `X-GitLab-Last-Update`,
			// and then watching on a key
			h.ServeHTTP(w, r)
			return
		}

		queueKey, err := readRunnerQueueKey(w, r)
		if err != nil {
			helper.Fail500(w, r, err)
			return
		}

		result, err := redis.WatchKey(queueKey, lastUpdate, pollingDuration)
		if err != nil {
			helper.Fail500(w, r, err)
			return
		}

		switch result {
		// It means that we detected a change before starting watching on change,
		// We proxy request to Rails, to see whether we can receive the build
		case redis.WatchKeyStatusAlreadyChanged:
			h.ServeHTTP(w, r)

		// It means that we detected a change after watching.
		// We could potentially proxy request to Rails, but...
		// We can end-up with unreliable responses,
		// as don't really know whether ResponseWriter is still in a sane state,
		// whether the connection is not dead
		case redis.WatchKeyStatusSeenChange:
			w.WriteHeader(204)

		// When we receive one of these statuses, it means that we detected no change,
		// so we return to runner 204, which means nothing got changed,
		// and there's no new builds to process
		case redis.WatchKeyStatusTimeout, redis.WatchKeyStatusNoChange:
			w.WriteHeader(204)
		}
	})
}

package builds

import (
	"net/http"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/redis"
)

const (
	maxRegisterBodySize   = 4 * 1024
	runnerBuildQueue      = "runner:build_queue:"
	runnerBuildQueueKey   = "token"
	runnerBuildQueueValue = "X-GitLab-Last-Update"
)

var (
	registerHandlerHits = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_builds_register_handler",
			Help: "How many connections gitlab-workhorse has opened in total. Can be used to track Redis connection rate for this process",
		},
		[]string{"status"},
	)
)

type largeBodyError struct{ error }
type watchError struct{ error }

func init() {
	prometheus.MustRegister(
		registerHandlerHits,
	)
}

func readRunnerToken(r *http.Request) (string, error) {
	err := r.ParseForm()
	if err != nil {
		return "", err
	}

	token := r.FormValue(runnerBuildQueueKey)
	return token, nil
}

func RegisterHandler(h http.Handler, pollingDuration time.Duration) http.Handler {
	if pollingDuration == 0 {
		return h
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lastUpdate := r.Header.Get(runnerBuildQueueValue)
		if lastUpdate == "" {
			// The client doesn't have update, fail
			registerHandlerHits.WithLabelValues("missing-value").Inc()
			h.ServeHTTP(w, r)
			return
		}

		requestBody, err := helper.ReadRequestBody(w, r, maxRegisterBodySize)
		if err != nil {
			registerHandlerHits.WithLabelValues("body-read-error").Inc()
			helper.Fail500(w, r, &largeBodyError{err})
			return
		}

		runnerToken, err := readRunnerToken(helper.CloneRequestWithNewBody(r, requestBody))
		if runnerToken == "" || err != nil {
			registerHandlerHits.WithLabelValues("body-parse-error").Inc()
			h.ServeHTTP(w, r)
			return
		}

		result, err := redis.WatchKey(runnerBuildQueue+runnerToken, lastUpdate, pollingDuration)
		if err != nil {
			registerHandlerHits.WithLabelValues("watch-error").Inc()
			helper.Fail500(w, r, &watchError{err})
			return
		}

		switch result {
		// It means that we detected a change before starting watching on change,
		// We proxy request to Rails, to see whether we can receive the build
		case redis.WatchKeyStatusAlreadyChanged:
			registerHandlerHits.WithLabelValues("already-changed").Inc()
			h.ServeHTTP(w, helper.CloneRequestWithNewBody(r, requestBody))

		// It means that we detected a change after watching.
		// We could potentially proxy request to Rails, but...
		// We can end-up with unreliable responses,
		// as don't really know whether ResponseWriter is still in a sane state,
		// whether the connection is not dead
		case redis.WatchKeyStatusSeenChange:
			registerHandlerHits.WithLabelValues("seen-change").Inc()
			w.WriteHeader(204)

		// When we receive one of these statuses, it means that we detected no change,
		// so we return to runner 204, which means nothing got changed,
		// and there's no new builds to process
		case redis.WatchKeyStatusTimeout:
			registerHandlerHits.WithLabelValues("timeout").Inc()
			w.WriteHeader(204)

		case redis.WatchKeyStatusNoChange:
			registerHandlerHits.WithLabelValues("no-change").Inc()
			w.WriteHeader(204)
		}
	})
}

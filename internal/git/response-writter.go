package git

import (
	"net/http"
	"strconv"

	"github.com/prometheus/client_golang/prometheus"
)

const (
	directionIn  = "in"
	directionOut = "out"
)

var (
	gitHTTPSessionsActive = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_git_http_sessions_active",
		Help: "Number of Git HTTP request-response cycles currently being handled by gitlab-workhorse.",
	})

	gitHTTPRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_http_requests",
			Help: "How many Git HTTP requests have been processed by gitlab-workhorse, partitioned by request type and agent.",
		},
		[]string{"method", "code", "service", "agent"},
	)

	gitHTTPBytes = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_git_http_bytes",
			Help: "How many Git HTTP bytes have been sent by gitlab-workhorse, partitioned by request type, agent and direction.",
		},
		[]string{"method", "code", "service", "agent", "direction"},
	)
)

func init() {
	prometheus.MustRegister(gitHTTPSessionsActive)
	prometheus.MustRegister(gitHTTPRequests)
	prometheus.MustRegister(gitHTTPBytes)
}

type GitHttpResponseWriter struct {
	rw      http.ResponseWriter
	status  int
	written int64
}

func NewGitHttpResponseWriter(rw http.ResponseWriter) *GitHttpResponseWriter {
	gitHTTPSessionsActive.Inc()
	return &GitHttpResponseWriter{
		rw: rw,
	}
}

func (w *GitHttpResponseWriter) Header() http.Header {
	return w.rw.Header()
}

func (w *GitHttpResponseWriter) Write(data []byte) (n int, err error) {
	if w.status == 0 {
		w.WriteHeader(http.StatusOK)
	}

	n, err = w.rw.Write(data)
	w.written += int64(n)
	return n, err
}

func (w *GitHttpResponseWriter) WriteHeader(status int) {
	if w.status != 0 {
		return
	}

	w.status = status
	w.rw.WriteHeader(status)
}

func (w *GitHttpResponseWriter) Log(r *http.Request, writtenIn int64) {
	service := getService(r)
	agent := getRequestAgent(r)

	gitHTTPSessionsActive.Dec()
	gitHTTPRequests.WithLabelValues(r.Method, strconv.Itoa(w.status), service, agent).Inc()
	gitHTTPBytes.WithLabelValues(r.Method, strconv.Itoa(w.status), service, agent, directionIn).
		Add(float64(writtenIn))
	gitHTTPBytes.WithLabelValues(r.Method, strconv.Itoa(w.status), service, agent, directionOut).
		Add(float64(w.written))
}

func getRequestAgent(r *http.Request) string {
	u, _, ok := r.BasicAuth()
	if !ok {
		return "anonymous"
	}

	if u == "gitlab-ci-token" {
		return "gitlab-ci"
	}

	return "logged"
}

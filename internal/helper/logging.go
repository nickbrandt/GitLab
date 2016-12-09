package helper

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

var (
	responseLogger *log.Logger

	sessionsActive = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_http_sessions_active",
		Help: "Number of HTTP request-response cycles currently being handled by gitlab-workhorse.",
	})

	requestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_http_requests_total",
			Help: "How many HTTP requests have been processed by gitlab-workhorse, partitioned by status code and HTTP method.",
		},
		[]string{"code", "method"},
	)
)

func init() {
	SetCustomResponseLogger(os.Stderr)
	registerPrometheusMetrics()
}

func SetCustomResponseLogger(writer io.Writer) {
	responseLogger = log.New(writer, "", 0)
}

func registerPrometheusMetrics() {
	prometheus.MustRegister(sessionsActive)
	prometheus.MustRegister(requestsTotal)
}

type LoggingResponseWriter interface {
	http.ResponseWriter

	Log(r *http.Request)
}

type loggingResponseWriter struct {
	rw      http.ResponseWriter
	status  int
	written int64
	started time.Time
}

type hijackingResponseWriter struct {
	loggingResponseWriter
}

func NewLoggingResponseWriter(rw http.ResponseWriter) LoggingResponseWriter {
	sessionsActive.Inc()
	out := loggingResponseWriter{
		rw:      rw,
		started: time.Now(),
	}

	if _, ok := rw.(http.Hijacker); ok {
		return &hijackingResponseWriter{out}
	}

	return &out
}

func (l *hijackingResponseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	// The only way to gethere is through NewLoggingResponseWriter(), which
	// checks that this cast will be valid.
	hijacker := l.rw.(http.Hijacker)
	return hijacker.Hijack()
}

func (l *loggingResponseWriter) Header() http.Header {
	return l.rw.Header()
}

func (l *loggingResponseWriter) Write(data []byte) (n int, err error) {
	if l.status == 0 {
		l.WriteHeader(http.StatusOK)
	}
	n, err = l.rw.Write(data)
	l.written += int64(n)
	return
}

func (l *loggingResponseWriter) WriteHeader(status int) {
	if l.status != 0 {
		return
	}

	l.status = status
	l.rw.WriteHeader(status)
}

func (l *loggingResponseWriter) Log(r *http.Request) {
	duration := time.Since(l.started)
	responseLogger.Printf("%s %s - - [%s] %q %d %d %q %q %f\n",
		r.Host, r.RemoteAddr, l.started,
		fmt.Sprintf("%s %s %s", r.Method, r.RequestURI, r.Proto),
		l.status, l.written, r.Referer(), r.UserAgent(), duration.Seconds(),
	)

	sessionsActive.Dec()
	requestsTotal.WithLabelValues(strconv.Itoa(l.status), r.Method).Inc()
}

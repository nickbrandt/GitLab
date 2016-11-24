package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
)

var (
	RequestsActive = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_requests_active",
		Help: "Number of HTTP requests currently being handled by gitlab-workhorse.",
	})
	RequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_requests_total",
			Help: "How many HTTP requests have been processed by gitlab-workhorse, partitioned by status code and HTTP method.",
		},
		[]string{"code", "method"},
	)
)

func init() {
	prometheus.MustRegister(RequestsActive)
	prometheus.MustRegister(RequestsTotal)
}

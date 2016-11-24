package metrics

import (
	"github.com/prometheus/client_golang/prometheus"
)

var (
	RequestsActive = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "http_requests_active",
		Help: "Number of HTTP requests currently being handled.",
	})
	RequestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "http_requests_total",
			Help: "How many HTTP requests processed, partitioned by status code and HTTP method.",
		},
		[]string{"code", "method"},
	)
)

func init() {
	prometheus.MustRegister(RequestsActive)
	prometheus.MustRegister(RequestsTotal)
}

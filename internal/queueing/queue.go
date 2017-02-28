package queueing

import (
	"errors"
	"time"

	"github.com/prometheus/client_golang/prometheus"
)

type errTooManyRequests struct{ error }
type errQueueingTimedout struct{ error }

var ErrTooManyRequests = &errTooManyRequests{errors.New("too many requests queued")}
var ErrQueueingTimedout = &errQueueingTimedout{errors.New("queueing timedout")}

type queueMetrics struct {
	queueingLimit        prometheus.Gauge
	queueingQueueLimit   prometheus.Gauge
	queueingQueueTimeout prometheus.Gauge
	queueingBusy         prometheus.Gauge
	queueingWaiting      prometheus.Gauge
	queueingWaitingTime  prometheus.Histogram
	queueingErrors       *prometheus.CounterVec
}

func NewQueueMetrics(timeout time.Duration) *queueMetrics {
	waitingTimeBuckets := []float64{
		timeout.Seconds() * 0.01,
		timeout.Seconds() * 0.05,
		timeout.Seconds() * 0.10,
		timeout.Seconds() * 0.25,
		timeout.Seconds() * 0.50,
		timeout.Seconds() * 0.75,
		timeout.Seconds() * 0.90,
		timeout.Seconds() * 0.95,
		timeout.Seconds() * 0.99,
		timeout.Seconds(),
		timeout.Seconds() * 1.5,
		timeout.Seconds() * 2,
	}

	metrics := &queueMetrics{
		queueingLimit: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "gitlab_workhorse_queueing_limit",
			Help: "Current limit set for the queueing mechanism",
		}),

		queueingQueueLimit: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "gitlab_workhorse_queueing_queue_limit",
			Help: "Current queueLimit set for the queueing mechanism",
		}),

		queueingQueueTimeout: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "gitlab_workhorse_queueing_queue_timeout",
			Help: "Current queueTimeout set for the queueing mechanism",
		}),

		queueingBusy: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "gitlab_workhorse_queueing_busy",
			Help: "How many queued requests are now processed",
		}),

		queueingWaiting: prometheus.NewGauge(prometheus.GaugeOpts{
			Name: "gitlab_workhorse_queueing_waiting",
			Help: "How many requests are now queued",
		}),

		queueingWaitingTime: prometheus.NewHistogram(prometheus.HistogramOpts{
			Name:    "gitlab_workhorse_queueing_waiting_time",
			Help:    "How many time a request spent in queue",
			Buckets: waitingTimeBuckets,
		}),

		queueingErrors: prometheus.NewCounterVec(
			prometheus.CounterOpts{
				Name: "gitlab_workhorse_queueing_errors",
				Help: "How many times the TooManyRequests or QueueintTimedout errors were returned while queueing, partitioned by error type",
			},
			[]string{"type"},
		),
	}

	prometheus.MustRegister(metrics.queueingLimit)
	prometheus.MustRegister(metrics.queueingQueueLimit)
	prometheus.MustRegister(metrics.queueingQueueTimeout)
	prometheus.MustRegister(metrics.queueingBusy)
	prometheus.MustRegister(metrics.queueingWaiting)
	prometheus.MustRegister(metrics.queueingWaitingTime)
	prometheus.MustRegister(metrics.queueingErrors)

	return metrics
}

type Queue struct {
	*queueMetrics

	busyCh    chan struct{}
	waitingCh chan time.Time
	timeout   time.Duration
}

// NewQueue creates a new queue
// limit specifies number of requests run concurrently
// queueLimit specifies maximum number of requests that can be queued
// timeout specifies the time limit of storing the request in the queue
// if the number of requests is above the limit
func NewQueue(limit, queueLimit uint, timeout time.Duration) *Queue {
	queue := &Queue{
		busyCh:    make(chan struct{}, limit),
		waitingCh: make(chan time.Time, limit+queueLimit),
		timeout:   timeout,
	}

	queue.queueMetrics = NewQueueMetrics(timeout)
	queue.queueingLimit.Set(float64(limit))
	queue.queueingQueueLimit.Set(float64(queueLimit))
	queue.queueingQueueTimeout.Set(timeout.Seconds())

	return queue
}

// Acquire takes one slot from the Queue
// and returns when a request should be processed
// it allows up to (limit) of requests running at a time
// it allows to queue up to (queue-limit) requests
func (s *Queue) Acquire() (err error) {
	// push item to a queue to claim your own slot (non-blocking)
	select {
	case s.waitingCh <- time.Now():
		s.queueingWaiting.Inc()
		break
	default:
		s.queueingErrors.WithLabelValues("too_many_requests").Inc()
		return ErrTooManyRequests
	}

	defer func() {
		if err != nil {
			waitStarted := <-s.waitingCh
			s.queueingWaiting.Dec()
			s.queueingWaitingTime.Observe(float64(time.Since(waitStarted).Seconds()))
		}
	}()

	// fast path: push item to current processed items (non-blocking)
	select {
	case s.busyCh <- struct{}{}:
		s.queueingBusy.Inc()
		return nil
	default:
		break
	}

	timer := time.NewTimer(s.timeout)
	defer timer.Stop()

	// push item to current processed items (blocking)
	select {
	case s.busyCh <- struct{}{}:
		s.queueingBusy.Inc()
		return nil

	case <-timer.C:
		s.queueingErrors.WithLabelValues("queueing_timedout").Inc()
		return ErrQueueingTimedout
	}
}

// Release marks the finish of processing of requests
// It triggers next request to be processed if it's in queue
func (s *Queue) Release() {
	// dequeue from queue to allow next request to be processed
	waitStarted := <-s.waitingCh
	s.queueingWaiting.Dec()
	s.queueingWaitingTime.Observe(float64(time.Since(waitStarted).Seconds()))

	<-s.busyCh
	s.queueingBusy.Dec()
}

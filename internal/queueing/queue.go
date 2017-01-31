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

var (
	queueingLimit = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_queueing_limit",
		Help: "Current limit set for the queueing mechanism",
	})

	queueingQueueLimit = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_queueing_queue_limit",
		Help: "Current queueLimit set for the queueing mechanism",
	})

	queueingBusy = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_queueing_busy",
		Help: "How many queued requests are now processed",
	})

	queueingWaiting = prometheus.NewGauge(prometheus.GaugeOpts{
		Name: "gitlab_workhorse_queueing_waiting",
		Help: "How many requests are now queued",
	})

	queueingErrors = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_queueing_errors",
			Help: "How many times the TooManyRequests or QueueintTimedout errors were returned while queueing, partitioned by error type",
		},
		[]string{"type"},
	)
)

type Queue struct {
	busyCh    chan struct{}
	waitingCh chan struct{}
}

func init() {
	prometheus.MustRegister(queueingErrors)
	prometheus.MustRegister(queueingLimit)
	prometheus.MustRegister(queueingBusy)
	prometheus.MustRegister(queueingWaiting)
	prometheus.MustRegister(queueingQueueLimit)
}

// NewQueue creates a new queue
// limit specifies number of requests run concurrently
// queueLimit specifies maximum number of requests that can be queued
// if the number of requests is above the limit
func NewQueue(limit, queueLimit uint) *Queue {
	queueingLimit.Set(float64(limit))
	queueingQueueLimit.Set(float64(queueLimit))

	return &Queue{
		busyCh:    make(chan struct{}, limit),
		waitingCh: make(chan struct{}, limit+queueLimit),
	}
}

// Acquire takes one slot from the Queue
// and returns when a request should be processed
// it allows up to (limit) of requests running at a time
// it allows to queue up to (queue-limit) requests
func (s *Queue) Acquire(timeout time.Duration) (err error) {
	// push item to a queue to claim your own slot (non-blocking)
	select {
	case s.waitingCh <- struct{}{}:
		queueingWaiting.Inc()
		break
	default:
		queueingErrors.WithLabelValues("too_many_requests").Inc()
		return ErrTooManyRequests
	}

	defer func() {
		if err != nil {
			<-s.waitingCh
			queueingWaiting.Dec()
		}
	}()

	// fast path: push item to current processed items (non-blocking)
	select {
	case s.busyCh <- struct{}{}:
		queueingBusy.Inc()
		return nil
	default:
		break
	}

	timer := time.NewTimer(timeout)
	defer timer.Stop()

	// push item to current processed items (blocking)
	select {
	case s.busyCh <- struct{}{}:
		queueingBusy.Inc()
		return nil

	case <-timer.C:
		queueingErrors.WithLabelValues("queueing_timedout").Inc()
		return ErrQueueingTimedout
	}
}

// Release marks the finish of processing of requests
// It triggers next request to be processed if it's in queue
func (s *Queue) Release() {
	// dequeue from queue to allow next request to be processed
	<-s.waitingCh
	queueingWaiting.Dec()
	<-s.busyCh
	queueingBusy.Dec()
}

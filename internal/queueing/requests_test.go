package queueing_test

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	. "gitlab.com/gitlab-org/gitlab-workhorse/internal/queueing"
)

var httpHandler = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "OK")
})

func slowHttpHandler(closeCh chan struct{}) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		<-closeCh
		fmt.Fprintln(w, "OK")
	})
}

func TestQueueRequests(t *testing.T) {
	w := httptest.NewRecorder()
	h := QueueRequests(httpHandler, 1, 2, time.Second)
	h.ServeHTTP(w, nil)
	if w.Code != 200 {
		t.Fatal("QueueRequests should process request")
	}
}

func testSlowRequestProcessing(count, limit, queueLimit int, queueTimeout time.Duration) *httptest.ResponseRecorder {
	closeCh := make(chan struct{})
	defer close(closeCh)

	handler := QueueRequests(slowHttpHandler(closeCh), limit, queueLimit, queueTimeout)

	respCh := make(chan *httptest.ResponseRecorder, count)

	// queue requests to use up the queue
	for count > 0 {
		go func() {
			w := httptest.NewRecorder()
			handler.ServeHTTP(w, nil)
			respCh <- w
		}()
		count--
	}

	// dequeue first request
	return <-respCh
}

func TestQueueingTimeout(t *testing.T) {
	w := testSlowRequestProcessing(2, 1, 2, time.Microsecond)

	if w.Code != 503 {
		t.Fatal("QueueRequests should timeout queued request")
	}
}

func TestQueuedRequests(t *testing.T) {
	w := testSlowRequestProcessing(3, 1, 2, time.Minute)

	if w.Code != 429 {
		t.Fatal("QueueRequests should return immediately and return too many requests")
	}
}

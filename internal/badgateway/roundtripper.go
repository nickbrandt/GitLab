package badgateway

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

// Error is a custom error for pretty Sentry 'issues'
type sentryError struct{ error }

type roundTripper struct {
	next            http.RoundTripper
	developmentMode bool
}

// NewRoundTripper creates a RoundTripper with a provided underlying next transport
func NewRoundTripper(developmentMode bool, next http.RoundTripper) http.RoundTripper {
	return &roundTripper{next: next, developmentMode: developmentMode}
}

func (t *roundTripper) RoundTrip(r *http.Request) (*http.Response, error) {
	start := time.Now()

	res, err := t.next.RoundTrip(r)
	if err == nil {
		return res, err
	}

	// httputil.ReverseProxy translates all errors from this
	// RoundTrip function into 500 errors. But the most likely error
	// is that the Rails app is not responding, in which case users
	// and administrators expect to see a 502 error. To show 502s
	// instead of 500s we catch the RoundTrip error here and inject a
	// 502 response.
	fields := log.Fields{"duration_ms": int64(time.Since(start).Seconds() * 1000)}
	helper.LogErrorWithFields(
		r,
		&sentryError{fmt.Errorf("badgateway: failed to receive response: %v", err)},
		fields,
	)

	message := "GitLab is not responding"
	if t.developmentMode {
		message = err.Error()
	}

	injectedResponse := &http.Response{
		StatusCode: http.StatusBadGateway,
		Status:     http.StatusText(http.StatusBadGateway),

		Request:    r,
		ProtoMajor: r.ProtoMajor,
		ProtoMinor: r.ProtoMinor,
		Proto:      r.Proto,
		Header:     make(http.Header),
		Trailer:    make(http.Header),
		Body:       ioutil.NopCloser(bytes.NewBufferString(message)),
	}
	injectedResponse.Header.Set("Content-Type", "text/plain")

	return injectedResponse, nil
}

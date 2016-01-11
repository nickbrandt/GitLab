package badgateway

import (
	"../helper"
	"bytes"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"sync"
	"time"
)

// Values from http.DefaultTransport
var DefaultDialer = &net.Dialer{
	Timeout:   30 * time.Second,
	KeepAlive: 30 * time.Second,
}

type RoundTripper struct {
	Socket                    string
	ProxyHeadersTimeout       time.Duration
	Transport                 *http.Transport
	configureRoundTripperOnce sync.Once
}

func (t *RoundTripper) RoundTrip(r *http.Request) (res *http.Response, err error) {
	t.configureRoundTripperOnce.Do(t.configureRoundTripper)

	res, err = t.Transport.RoundTrip(r)

	// httputil.ReverseProxy translates all errors from this
	// RoundTrip function into 500 errors. But the most likely error
	// is that the Rails app is not responding, in which case users
	// and administrators expect to see a 502 error. To show 502s
	// instead of 500s we catch the RoundTrip error here and inject a
	// 502 response.
	if err != nil {
		helper.LogError(fmt.Errorf("proxyRoundTripper: %s %q failed with: %q", r.Method, r.RequestURI, err))

		res = &http.Response{
			StatusCode: http.StatusBadGateway,
			Status:     http.StatusText(http.StatusBadGateway),

			Request:    r,
			ProtoMajor: r.ProtoMajor,
			ProtoMinor: r.ProtoMinor,
			Proto:      r.Proto,
			Header:     make(http.Header),
			Trailer:    make(http.Header),
			Body:       ioutil.NopCloser(bytes.NewBufferString(err.Error())),
		}
		res.Header.Set("Content-Type", "text/plain")
		err = nil
	}
	return
}

func (t *RoundTripper) configureRoundTripper() {
	if t.Transport != nil {
		return
	}

	// Clone http.DefaultTransport. Needs a cast from http.RoundTripper to *http.Transport.
	tr := *(http.DefaultTransport.(*http.Transport))
	tr.ResponseHeaderTimeout = t.ProxyHeadersTimeout

	if t.Socket != "" {
		tr.Dial = func(_, _ string) (net.Conn, error) {
			return DefaultDialer.Dial("unix", t.Socket)
		}
	}

	t.Transport = &tr
}

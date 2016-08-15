package badgateway

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

// Values from http.DefaultTransport
var DefaultDialer = &net.Dialer{
	Timeout:   30 * time.Second,
	KeepAlive: 30 * time.Second,
}

var DefaultTransport = &http.Transport{
	Proxy:               http.ProxyFromEnvironment, // from http.DefaultTransport
	Dial:                DefaultDialer.Dial,        // from http.DefaultTransport
	TLSHandshakeTimeout: 10 * time.Second,          // from http.DefaultTransport
}

type RoundTripper struct {
	Transport *http.Transport
}

func TestRoundTripper(backend *url.URL) *RoundTripper {
	return NewRoundTripper(backend, "", 0)
}

func NewRoundTripper(backend *url.URL, socket string, proxyHeadersTimeout time.Duration) *RoundTripper {
	tr := *DefaultTransport
	tr.ResponseHeaderTimeout = proxyHeadersTimeout

	if backend != nil && socket == "" {
		address := mustParseAddress(backend.Host, backend.Scheme)
		tr.Dial = func(_, _ string) (net.Conn, error) {
			return DefaultDialer.Dial("tcp", address)
		}
	} else if socket != "" {
		tr.Dial = func(_, _ string) (net.Conn, error) {
			return DefaultDialer.Dial("unix", socket)
		}
	} else {
		panic("backend is nil and socket is empty")
	}

	return &RoundTripper{Transport: &tr}
}

func mustParseAddress(address, scheme string) string {
	if host, port, err := net.SplitHostPort(address); err == nil {
		return host + ":" + port
	}

	address = address + ":" + scheme
	if host, port, err := net.SplitHostPort(address); err == nil {
		return host + ":" + port
	}

	panic("could not parse host/port from  addres / scheme")
}

func (t *RoundTripper) RoundTrip(r *http.Request) (res *http.Response, err error) {
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

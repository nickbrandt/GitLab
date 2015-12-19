package proxy

import (
	"../helper"
	"bytes"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
)

type Proxy struct {
	URL                       *url.URL
	Version                   string
	Transport                 http.RoundTripper
	_reverseProxy             *httputil.ReverseProxy
	configureReverseProxyOnce sync.Once
}

func (p *Proxy) reverseProxy() *httputil.ReverseProxy {
	p.configureReverseProxyOnce.Do(p.configureReverseProxy)
	return p._reverseProxy
}

func (p *Proxy) configureReverseProxy() {
	u := *p.URL // Make a copy of p.URL
	u.Path = ""
	p._reverseProxy = httputil.NewSingleHostReverseProxy(&u)
	p._reverseProxy.Transport = p.Transport
}

type RoundTripper struct {
	Transport http.RoundTripper
}

func (rt *RoundTripper) RoundTrip(r *http.Request) (res *http.Response, err error) {
	res, err = rt.Transport.RoundTrip(r)

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

func HeaderClone(h http.Header) http.Header {
	h2 := make(http.Header, len(h))
	for k, vv := range h {
		vv2 := make([]string, len(vv))
		copy(vv2, vv)
		h2[k] = vv2
	}
	return h2
}

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Clone request
	req := *r
	req.Header = HeaderClone(r.Header)

	// Set Workhorse version
	req.Header.Set("Gitlab-Workhorse", p.Version)
	rw := newSendFileResponseWriter(w, &req)
	defer rw.Flush()

	p.reverseProxy().ServeHTTP(&rw, &req)
}

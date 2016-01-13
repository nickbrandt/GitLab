package proxy

import (
	"../badgateway"
	"net/http"
	"net/http/httputil"
	"net/url"
	"sync"
)

type Proxy struct {
	URL                       *url.URL
	Version                   string
	RoundTripper              *badgateway.RoundTripper
	_reverseProxy             *httputil.ReverseProxy
	configureReverseProxyOnce sync.Once
}

func (p *Proxy) reverseProxy() *httputil.ReverseProxy {
	p.configureReverseProxyOnce.Do(func() {
		u := *p.URL // Make a copy of p.URL
		u.Path = ""
		p._reverseProxy = httputil.NewSingleHostReverseProxy(&u)
		if p.RoundTripper != nil {
			p._reverseProxy.Transport = p.RoundTripper
		} else {
			p._reverseProxy.Transport = badgateway.NewRoundTripper("", 0)
		}
	})
	return p._reverseProxy
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

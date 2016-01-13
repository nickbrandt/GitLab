package proxy

import (
	"../badgateway"
	"net/http"
	"net/http/httputil"
	"net/url"
)

type Proxy struct {
	Version      string
	reverseProxy *httputil.ReverseProxy
}

func NewProxy(myURL *url.URL, version string, roundTripper *badgateway.RoundTripper) *Proxy {
	p := Proxy{Version: version}
	u := *myURL // Make a copy of p.URL
	u.Path = ""
	p.reverseProxy = httputil.NewSingleHostReverseProxy(&u)
	if roundTripper != nil {
		p.reverseProxy.Transport = roundTripper
	} else {
		p.reverseProxy.Transport = badgateway.NewRoundTripper("", 0)
	}
	return &p
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

	p.reverseProxy.ServeHTTP(&rw, &req)
}

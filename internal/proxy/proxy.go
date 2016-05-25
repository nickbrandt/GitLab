package proxy

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"
	"time"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/badgateway"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
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

func (p *Proxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Clone request
	req := *r
	req.Header = helper.HeaderClone(r.Header)

	// Set Workhorse version
	req.Header.Set("Gitlab-Workhorse", p.Version)
	req.Header.Set("Gitlab-Worhorse-Proxy-Start", fmt.Sprintf("%d", time.Now().UnixNano()))

	p.reverseProxy.ServeHTTP(w, &req)
}

package upstream

import (
	"../proxy"
	"net"
	"net/http"
	"time"
)

// Values from http.DefaultTransport
var DefaultDialer = &net.Dialer{
	Timeout:   30 * time.Second,
	KeepAlive: 30 * time.Second,
}

var DefaultTransport = &http.Transport{
	Proxy: http.ProxyFromEnvironment, // from http.DefaultTransport
	Dial:  DefaultDialer.Dial,        // from http.DefaultTransport
	ResponseHeaderTimeout: time.Minute,      // custom
	TLSHandshakeTimeout:   10 * time.Second, // from http.DefaultTransport
}

func (u *Upstream) Transport() http.RoundTripper {
	u.configureTransportOnce.Do(u.configureTransport)
	return u.transport
}

func (u *Upstream) configureTransport() {
	t := *DefaultTransport

	if u.ResponseHeaderTimeout != 0 {
		t.ResponseHeaderTimeout = u.ResponseHeaderTimeout
	}

	if u.Socket != "" {
		t.Dial = func(_, _ string) (net.Conn, error) {
			return DefaultDialer.Dial("unix", u.Socket)
		}
	}

	u.transport = &proxy.RoundTripper{&t}
}

package api

import (
	"crypto/tls"
	"crypto/x509"
	"net/http"
	"net/url"

	"github.com/gorilla/websocket"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

type TerminalSettings struct {
	// The channel provider may require use of a particular subprotocol. If so,
	// it must be specified here, and Workhorse must have a matching codec.
	Subprotocols []string

	// The websocket URL to connect to.
	Url string

	// Any headers (e.g., Authorization) to send with the websocket request
	Header http.Header

	// The CA roots to validate the remote endpoint with, for wss:// URLs. The
	// system-provided CA pool will be used if this is blank. PEM-encoded data.
	CAPem string

	// The value is specified in seconds. It is converted to time.Duration
	// later.
	MaxSessionTime int
}

func (t *TerminalSettings) URL() (*url.URL, error) {
	return url.Parse(t.Url)
}

func (t *TerminalSettings) Dialer() *websocket.Dialer {
	dialer := &websocket.Dialer{
		Subprotocols: t.Subprotocols,
	}

	if len(t.CAPem) > 0 {
		pool := x509.NewCertPool()
		pool.AppendCertsFromPEM([]byte(t.CAPem))
		dialer.TLSClientConfig = &tls.Config{RootCAs: pool}
	}

	return dialer
}

func (t *TerminalSettings) Clone() *TerminalSettings {
	// Doesn't clone the strings, but that's OK as strings are immutable in go
	cloned := *t
	cloned.Header = helper.HeaderClone(t.Header)
	return &cloned
}

func (t *TerminalSettings) Dial() (*websocket.Conn, *http.Response, error) {
	return t.Dialer().Dial(t.Url, t.Header)
}

func (t *TerminalSettings) Channel() *ChannelSettings {
	return &ChannelSettings{
		Subprotocols:   t.Subprotocols,
		Url:            t.Url,
		CAPem:          t.CAPem,
		MaxSessionTime: t.MaxSessionTime,
	}
}

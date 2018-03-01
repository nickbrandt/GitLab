package helper

import (
	"bytes"
	"fmt"

	log "github.com/sirupsen/logrus"
)

func forNil(v interface{}, otherwise interface{}) interface{} {
	if v == nil {
		return otherwise
	}

	return v
}

// accessLogFormatter formats logs into a format similar to the combined access log format
// See https://httpd.apache.org/docs/1.3/logs.html#combined
type accessLogFormatter struct {
	clock Clock
}

// Format renders a single log entry
func (f *accessLogFormatter) Format(entry *log.Entry) ([]byte, error) {
	host := forNil(entry.Data["host"], "-")
	remoteAddr := forNil(entry.Data["remoteAddr"], "")
	method := forNil(entry.Data["method"], "")
	uri := forNil(entry.Data["uri"], "")
	proto := forNil(entry.Data["proto"], "")
	status := forNil(entry.Data["status"], 0)
	written := forNil(entry.Data["written"], 0)
	referer := forNil(entry.Data["referer"], "")
	userAgent := forNil(entry.Data["userAgent"], "")
	duration := forNil(entry.Data["duration"], 0.0)

	now := f.clock.Now().Format("2006/01/02:15:04:05 -0700")

	requestLine := fmt.Sprintf("%s %s %s", method, uri, proto)

	buf := &bytes.Buffer{}
	_, err := fmt.Fprintf(buf, "%s %s - - [%s] %q %d %d %q %q %.3f\n",
		host, remoteAddr, now, requestLine,
		status, written, referer, userAgent, duration,
	)

	return buf.Bytes(), err
}

// NewAccessLogFormatter returns a new formatter for combined access logs
func NewAccessLogFormatter() log.Formatter {
	return &accessLogFormatter{clock: &RealClock{}}
}

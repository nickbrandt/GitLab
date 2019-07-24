package log

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

// combinedAccessLogFormatter formats logs into a format similar to the combined access log format
// See https://httpd.apache.org/docs/1.3/logs.html#combined
type combinedAccessLogFormatter struct {
	clock clock
}

// Format renders a single log entry
func (f *combinedAccessLogFormatter) Format(entry *log.Entry) ([]byte, error) {
	host := forNil(entry.Data[httpHostField], "-")
	remoteAddr := forNil(entry.Data[httpRemoteIPField], "")
	method := forNil(entry.Data[httpRequestMethodField], "")
	uri := forNil(entry.Data[httpURIField], "")
	proto := forNil(entry.Data[httpProtoField], "")
	status := forNil(entry.Data[httpResponseStatusCodeField], 0)
	written := forNil(entry.Data[httpResponseSizeField], 0)
	referer := forNil(entry.Data[httpRequestReferrerField], "")
	userAgent := forNil(entry.Data[httpUserAgentField], "")
	duration := forNil(entry.Data[requestDurationField], 0.0)

	now := f.clock.Now().Format("2006/01/02:15:04:05 -0700")

	requestLine := fmt.Sprintf("%s %s %s", method, uri, proto)

	buf := &bytes.Buffer{}
	_, err := fmt.Fprintf(buf, "%s %s - - [%s] %q %d %d %q %q %.3f\n",
		host, remoteAddr, now, requestLine,
		status, written, referer, userAgent, duration,
	)

	return buf.Bytes(), err
}

// newCombinedcombinedAccessLogFormatter returns a new formatter for combined access logs
func newCombinedcombinedAccessLogFormatter() log.Formatter {
	return &combinedAccessLogFormatter{clock: &realClock{}}
}

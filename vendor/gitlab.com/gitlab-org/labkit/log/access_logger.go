package log

import (
	"bufio"
	"net"
	"net/http"
	"time"

	"github.com/sebest/xff"
	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/mask"
)

// AccessLogger will generate access logs for the service.
func AccessLogger(h http.Handler, opts ...AccessLoggerOption) http.Handler {
	config := applyAccessLoggerOptions(opts)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lrw := newLoggingResponseWriter(w, &config)
		defer lrw.requestFinished(r)

		h.ServeHTTP(lrw, r)
	})
}

func newLoggingResponseWriter(rw http.ResponseWriter, config *accessLoggerConfig) notifiableResponseWriter {
	out := loggingResponseWriter{
		rw:      rw,
		started: time.Now(),
		config:  config,
	}

	// If the underlying response writer supports hijacking,
	// we need to ensure that we do too
	if _, ok := rw.(http.Hijacker); ok {
		return &hijackingResponseWriter{out}
	}

	return &out
}

// notifiableResponseWriter is a response writer that can be notified when the request is complete,
// via the requestFinished method
type notifiableResponseWriter interface {
	http.ResponseWriter

	// requestFinished is called by the middleware when the request has completed
	requestFinished(r *http.Request)
}

type loggingResponseWriter struct {
	rw          http.ResponseWriter
	status      int
	wroteHeader bool
	written     int64
	started     time.Time
	config      *accessLoggerConfig
}

func (l *loggingResponseWriter) Header() http.Header {
	return l.rw.Header()
}

func (l *loggingResponseWriter) Write(data []byte) (int, error) {
	if !l.wroteHeader {
		l.WriteHeader(http.StatusOK)
	}
	n, err := l.rw.Write(data)

	l.written += int64(n)
	return n, err
}

func (l *loggingResponseWriter) WriteHeader(status int) {
	if l.wroteHeader {
		return
	}
	l.wroteHeader = true
	l.status = status

	l.rw.WriteHeader(status)
}

func (l *loggingResponseWriter) accessLogFields(r *http.Request) logrus.Fields {
	duration := time.Since(l.started)

	fields := l.config.extraFields(r)
	fieldsBitMask := l.config.fields

	// Optionally add built in fields
	if fieldsBitMask&CorrelationID != 0 {
		fields[correlation.FieldName] = correlation.ExtractFromContext(r.Context())
	}

	if fieldsBitMask&HTTPHost != 0 {
		fields[httpHostField] = r.Host
	}

	if fieldsBitMask&HTTPRemoteIP != 0 {
		fields[httpRemoteIPField] = getRemoteIP(r)
	}

	if fieldsBitMask&HTTPRemoteAddr != 0 {
		fields[httpRemoteAddrField] = r.RemoteAddr
	}

	if fieldsBitMask&HTTPRequestMethod != 0 {
		fields[httpRequestMethodField] = r.Method
	}

	if fieldsBitMask&HTTPURI != 0 {
		fields[httpURIField] = mask.URL(r.RequestURI)
	}

	if fieldsBitMask&HTTPProto != 0 {
		fields[httpProtoField] = r.Proto
	}

	if fieldsBitMask&HTTPResponseStatusCode != 0 {
		fields[httpResponseStatusCodeField] = l.status
	}

	if fieldsBitMask&HTTPResponseSize != 0 {
		fields[httpResponseSizeField] = l.written
	}

	if fieldsBitMask&HTTPRequestReferrer != 0 {
		fields[httpRequestReferrerField] = mask.URL(r.Referer())
	}

	if fieldsBitMask&HTTPUserAgent != 0 {
		fields[httpUserAgentField] = r.UserAgent()
	}

	if fieldsBitMask&RequestDuration != 0 {
		fields[requestDurationField] = int64(duration / time.Millisecond)
	}

	if fieldsBitMask&System != 0 {
		fields[systemField] = "http"
	}

	return fields
}

func (l *loggingResponseWriter) requestFinished(r *http.Request) {
	l.config.logger.WithFields(l.accessLogFields(r)).Info("access")
}

// hijackingResponseWriter is like a loggingResponseWriter that supports the http.Hijacker interface
type hijackingResponseWriter struct {
	loggingResponseWriter
}

func (l *hijackingResponseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	// The only way to get here is through NewStatsCollectingResponseWriter(), which
	// checks that this cast will be valid.
	hijacker := l.rw.(http.Hijacker)
	return hijacker.Hijack()
}

func getRemoteIP(r *http.Request) string {
	remoteAddr := xff.GetRemoteAddr(r)
	host, _, err := net.SplitHostPort(remoteAddr)
	if err != nil {
		return r.RemoteAddr
	}

	return host
}

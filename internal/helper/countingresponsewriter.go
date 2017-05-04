package helper

import (
	"net/http"
)

type CountingResponseWriter interface {
	http.ResponseWriter
	Count() int64
}

type countingResponseWriter struct {
	rw     http.ResponseWriter
	status int
	count  int64
}

func NewCountingResponseWriter(rw http.ResponseWriter) CountingResponseWriter {
	return &countingResponseWriter{rw: rw}
}

func (c *countingResponseWriter) Header() http.Header {
	return c.rw.Header()
}

func (c *countingResponseWriter) Write(data []byte) (n int, err error) {
	if c.status == 0 {
		c.WriteHeader(http.StatusOK)
	}

	n, err = c.rw.Write(data)
	c.count += int64(n)
	return n, err
}

func (c *countingResponseWriter) WriteHeader(status int) {
	if c.status != 0 {
		return
	}

	c.status = status
	c.rw.WriteHeader(status)
}

func (c *countingResponseWriter) Count() int64 {
	return c.count
}

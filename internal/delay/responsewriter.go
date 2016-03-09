// Package delay exports delay.ResponseWriter. This type implements
// http.ResponseWriter with the ability to delay setting the HTTP
// response code (with WriteHeader()) until writing the first bufferSize
// bytes. This makes it possible, up to a point, to 'change your mind'
// about the HTTP status code. The caller must call
// ResponseWriter.Flush() before returning from the handler (e.g. using
// 'defer').

package delay

import (
	"bytes"
	"io"
	"net/http"
)

const bufferSize = 8192

type ResponseWriter struct {
	writer     http.ResponseWriter
	status     int
	bufWritten int
	cap        int
	flushed    bool
	buffer     *bytes.Buffer
}

func NewResponseWriter(w http.ResponseWriter) *ResponseWriter {
	return &ResponseWriter{
		writer: w,
		buffer: bytes.NewBuffer(make([]byte, 0, bufferSize)),
		cap:    bufferSize,
	}
}

func (rw *ResponseWriter) Write(buf []byte) (int, error) {
	if !rw.flushed && len(buf)+rw.bufWritten <= rw.cap {
		n, err := rw.buffer.Write(buf)
		rw.bufWritten += n
		return n, err
	}

	if err := rw.Flush(); err != nil {
		return 0, err
	}

	return rw.writer.Write(buf)
}

func (rw *ResponseWriter) Header() http.Header {
	return rw.writer.Header()
}

func (rw *ResponseWriter) WriteHeader(code int) {
	if rw.status != 0 {
		return
	}
	rw.status = code
}

func (rw *ResponseWriter) Flush() error {
	if rw.flushed {
		return nil
	}
	rw.flushed = true

	if rw.status == 0 {
		rw.writer.WriteHeader(http.StatusOK)
	} else {
		rw.writer.WriteHeader(rw.status)
	}

	_, err := io.Copy(rw.writer, rw.buffer)
	rw.buffer = nil // "Release" the buffer for GC
	return err
}

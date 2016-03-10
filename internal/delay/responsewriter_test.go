package delay

import (
	"fmt"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSanity(t *testing.T) {
	first, second := 200, 500
	w := httptest.NewRecorder()
	w.WriteHeader(first)
	w.WriteHeader(second)
	if code := w.Code; code != first {
		t.Fatalf("Expected HTTP code %d, got %d", first, code)
	}
}

func TestSmallResponse(t *testing.T) {
	code := 500
	body := "hello"
	w := httptest.NewRecorder()
	rw := NewResponseWriter(w)
	fmt.Fprint(rw, body)
	rw.WriteHeader(code)
	rw.Flush()

	if actualCode := w.Code; actualCode != code {
		t.Fatalf("Expected code %d, got %d", code, actualCode)
	}
	if actualBody := w.Body.String(); actualBody != body {
		t.Fatalf("Expected body %q, got %q", body, actualBody)
	}
}

func TestLargeResponse(t *testing.T) {
	code := 200
	body := strings.Repeat("0123456789", bufferSize/5) // must exceed the buffer size
	w := httptest.NewRecorder()
	rw := NewResponseWriter(w)
	fmt.Fprint(rw, body)
	// Because the 'body' was too long this 500 should be ignored
	rw.WriteHeader(500)
	rw.Flush()

	if actualCode := w.Code; actualCode != code {
		t.Fatalf("Expected code %d, got %d", code, actualCode)
	}
	if actualBody := w.Body.String(); actualBody != body {
		t.Fatalf("Expected body %q, got %q", body, actualBody)
	}
}

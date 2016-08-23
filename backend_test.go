package main

import (
	"testing"
)

func TestParseAuthBackend(t *testing.T) {
	failures := []string{
		"",
		"ftp://localhost",
		"https://example.com",
	}

	for _, example := range failures {
		if _, err := parseAuthBackend(example); err == nil {
			t.Errorf("error expected for %q", example)
		}
	}

	successes := []struct{ input, host, scheme string }{
		{"http://localhost:8080", "localhost:8080", "http"},
		{"localhost:3000", "localhost:3000", "http"},
		{"http://localhost", "localhost", "http"},
		{"localhost", "localhost", "http"},
	}

	for _, example := range successes {
		result, err := parseAuthBackend(example.input)
		if err != nil {
			t.Errorf("parse %q: %v", example.input, err)
			break
		}

		if result.Host != example.host {
			t.Errorf("example %q: expected %q, got %q", example.input, example.host, result.Host)
		}

		if result.Scheme != example.scheme {
			t.Errorf("example %q: expected %q, got %q", example.input, example.scheme, result.Scheme)
		}
	}
}

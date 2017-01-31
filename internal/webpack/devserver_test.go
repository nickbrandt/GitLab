package webpack

import (
	"testing"
)

func TestBuildURL(t *testing.T) {
	examples := []struct {
		input string
		ok    bool
	}{
		{"", false},
		{"localhost:5000", false},
		{"tcp://localhost:5000", true},
	}

	for _, ex := range examples {
		u, err := buildURL(ex.input)
		if ex.ok {
			if err != nil {
				t.Errorf("example %v: expected no error, got %v", ex, err)
			}
			expectedScheme := "http"
			if u.Scheme != expectedScheme {
				t.Errorf("example %v: expected scheme %q, got %q", ex, expectedScheme, u.Scheme)
			}
		} else {
			if err == nil {
				t.Errorf("example %v: expected error, got none", ex)
			}
		}
	}
}

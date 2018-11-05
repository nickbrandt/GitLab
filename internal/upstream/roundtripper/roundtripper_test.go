package roundtripper

import (
	"testing"
)

func TestMustParseAddress(t *testing.T) {
	successExamples := []struct{ address, scheme, expected string }{
		{"1.2.3.4:56", "http", "1.2.3.4:56"},
		{"[::1]:23", "http", "::1:23"},
		{"4.5.6.7", "http", "4.5.6.7:http"},
	}
	for _, example := range successExamples {
		result := mustParseAddress(example.address, example.scheme)
		if example.expected != result {
			t.Errorf("expected %q, got %q", example.expected, result)
		}
	}

	panicExamples := []struct{ address, scheme string }{
		{"1.2.3.4", ""},
		{"1.2.3.4", "https"},
	}

	for _, panicExample := range panicExamples {
		func() {
			defer func() {
				if r := recover(); r == nil {
					t.Errorf("expected panic for %v but none occurred", panicExample)
				}
			}()
			t.Log(mustParseAddress(panicExample.address, panicExample.scheme))
		}()
	}
}

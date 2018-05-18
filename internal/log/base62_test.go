package log

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestReverseBase62Conversion(t *testing.T) {
	tests := []struct {
		n        int64
		expected string
	}{
		{n: 0, expected: "0"},
		{n: 5, expected: "5"},
		{n: 10, expected: "a"},
		{n: 62, expected: "01"},
		{n: 620, expected: "0a"},
		{n: 6200, expected: "0C1"},
	}

	for _, test := range tests {
		t.Run(fmt.Sprintf("%d_to_%s", test.n, test.expected), func(t *testing.T) {
			assert.Equal(t, test.expected, encodeReverseBase62(test.n))
		})
	}
}

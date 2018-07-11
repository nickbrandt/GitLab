package log

import (
	"bytes"
	"crypto/rand"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestInjectCorrelationID(t *testing.T) {
	tests := []struct {
		name       string
		randSource io.Reader
	}{
		{name: "Entropy Available", randSource: rand.Reader},
		{name: "No Entropy", randSource: &bytes.Buffer{}},
	}

	defer func() {
		randSource = rand.Reader
	}()

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			invoked := false
			randSource = test.randSource

			h := InjectCorrelationID(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
				invoked = true

				ctx := r.Context()
				correlationID := ctx.Value(KeyCorrelationID)
				require.NotNil(t, correlationID, "CorrelationID is missing")
				require.NotEmpty(t, correlationID, "CorrelationID is missing")
			}))

			r := httptest.NewRequest("GET", "http://example.com", nil)
			h.ServeHTTP(nil, r)

			assert.True(t, invoked, "handler not executed")
		})
	}
}

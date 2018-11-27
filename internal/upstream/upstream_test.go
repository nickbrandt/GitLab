package upstream

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// This test doesn't actually listen for a connection so there may be
// some error spew that can be ignored.
func TestXForwardedForHeaders(t *testing.T) {
	testCases := []struct {
		initial   string
		forwarded string
		expected  string
	}{
		{initial: "@", forwarded: "", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
		{initial: "@", forwarded: "127.0.0.1", expected: "127.0.0.1:0"},
		{initial: "@", forwarded: "192.168.0.1", expected: "127.0.0.1:0"},
		{initial: "192.168.1.1:0", forwarded: "", expected: "192.168.1.1:0"},
		{initial: "192.168.1.1:0", forwarded: "18.245.0.1", expected: "18.245.0.1:0"},
	}

	for _, tc := range testCases {
		req, err := http.NewRequest("POST", "unix:///tmp/test.socket/info/refs", nil)
		require.NoError(t, err)

		req.RemoteAddr = tc.initial

		if tc.forwarded != "" {
			req.Header.Add("X-Forwarded-For", tc.forwarded)
		}

		config := config.Config{}
		u := NewUpstream(config)

		resp := httptest.NewRecorder()
		u.ServeHTTP(resp, req)

		assert.Equal(t, tc.expected, req.RemoteAddr)
	}
}

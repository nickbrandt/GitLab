package correlation

import (
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func Test_generateRandomCorrelationID(t *testing.T) {
	require := require.New(t)

	got, err := generateRandomCorrelationID()
	require.NoError(err)
	require.NotEqual(got, "", "Expected a non-empty string response")
}

func Test_generatePseudorandomCorrelationID(t *testing.T) {
	require := require.New(t)

	req, err := http.NewRequest("GET", "http://example.com", nil)
	require.NoError(err)

	got := generatePseudorandomCorrelationID(req)
	require.NotEqual(got, "", "Expected a non-empty string response")
	require.True(strings.HasPrefix(got, "E:"), "Expected the psuedorandom correlator to have an `E:` prefix")
}

func Test_generateRandomCorrelationIDWithFallback(t *testing.T) {
	require := require.New(t)

	req, err := http.NewRequest("GET", "http://example.com", nil)
	require.NoError(err)

	got := generateRandomCorrelationIDWithFallback(req)
	require.NotEqual(got, "", "Expected a non-empty string response")
	require.False(strings.HasPrefix(got, "E:"), "Not expecting fallback to pseudorandom correlationID")
}

package correlation

import (
	"context"
	"errors"
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
)

var httpCorrelationTests = []struct {
	name          string
	ctx           context.Context
	correlationID string
	hasHeader     bool
}{
	{
		name:          "nil with value",
		ctx:           nil,
		correlationID: "CORRELATION_ID",
		hasHeader:     true,
	},
	{
		name:          "nil without value",
		ctx:           nil,
		correlationID: "",
		hasHeader:     false,
	},
	{
		name:          "context with value",
		ctx:           context.Background(),
		correlationID: "CORRELATION_ID",
		hasHeader:     true,
	},
	{
		name:          "context without value",
		ctx:           context.Background(),
		correlationID: "",
		hasHeader:     false,
	},
}

func Test_injectRequest(t *testing.T) {
	for _, tt := range httpCorrelationTests {
		t.Run(tt.name, func(t *testing.T) {
			require := require.New(t)

			ctx := context.WithValue(tt.ctx, keyCorrelationID, tt.correlationID)
			req, err := http.NewRequest("GET", "http://example.com", nil)
			require.NoError(err)

			req = req.WithContext(ctx)

			injectRequest(req)

			value := req.Header.Get(propagationHeader)
			require.True(tt.hasHeader == (value != ""), "Expected header existence %v. Instead got header %v", tt.hasHeader, value)

			if tt.hasHeader {
				require.Equal(tt.correlationID, value, "Expected header value %v, got %v", tt.correlationID, value)
			}
		})
	}
}

type delegatedRoundTripper struct {
	delegate func(req *http.Request) (*http.Response, error)
}

func (c delegatedRoundTripper) RoundTrip(req *http.Request) (*http.Response, error) {
	return c.delegate(req)
}

func roundTripperFunc(delegate func(req *http.Request) (*http.Response, error)) http.RoundTripper {
	return &delegatedRoundTripper{delegate}
}

func TestInstrumentedRoundTripper(t *testing.T) {
	for _, tt := range httpCorrelationTests {
		t.Run(tt.name, func(t *testing.T) {
			require := require.New(t)

			response := &http.Response{}
			mockTransport := roundTripperFunc(func(req *http.Request) (*http.Response, error) {
				value := req.Header.Get(propagationHeader)
				require.True(tt.hasHeader == (value != ""), "Expected header existence %v. Instead got header %v", tt.hasHeader, value)

				if tt.hasHeader {
					require.Equal(tt.correlationID, value, "Expected header value %v, got %v", tt.correlationID, value)
				}

				return response, nil
			})

			client := &http.Client{
				Transport: NewInstrumentedRoundTripper(mockTransport),
			}

			ctx := context.WithValue(tt.ctx, keyCorrelationID, tt.correlationID)
			req, err := http.NewRequest("GET", "http://example.com", nil)
			require.NoError(err)

			req = req.WithContext(ctx)

			res, err := client.Do(req)
			require.NoError(err)
			require.Equal(response, res)
		})
	}
}

func TestInstrumentedRoundTripperFailures(t *testing.T) {
	for _, tt := range httpCorrelationTests {
		t.Run(tt.name+" - with errors", func(t *testing.T) {
			require := require.New(t)

			testErr := errors.New("test")

			mockTransport := roundTripperFunc(func(req *http.Request) (*http.Response, error) {
				value := req.Header.Get(propagationHeader)
				require.True(tt.hasHeader == (value != ""), "Expected header existence %v. Instead got header %v", tt.hasHeader, value)

				if tt.hasHeader {
					require.Equal(tt.correlationID, value, "Expected header value %v, got %v", tt.correlationID, value)
				}

				return nil, testErr
			})

			client := &http.Client{
				Transport: NewInstrumentedRoundTripper(mockTransport),
			}

			ctx := context.WithValue(tt.ctx, keyCorrelationID, tt.correlationID)
			req, err := http.NewRequest("GET", "http://example.com", nil)
			require.NoError(err)

			req = req.WithContext(ctx)

			res, err := client.Do(req)
			require.Error(err)
			require.Nil(res)
		})
	}
}

func TestInstrumentedRoundTripperWithoutContext(t *testing.T) {
	require := require.New(t)

	response := &http.Response{}
	mockTransport := roundTripperFunc(func(req *http.Request) (*http.Response, error) {
		return response, nil
	})

	client := &http.Client{
		Transport: NewInstrumentedRoundTripper(mockTransport),
	}

	req, err := http.NewRequest("GET", "http://example.com", nil)
	require.NoError(err)

	res, err := client.Do(req)
	require.NoError(err)
	require.Equal(response, res)
}

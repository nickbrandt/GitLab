package correlation

import (
	"net/http"
)

// InjectCorrelationID is an HTTP middleware to generate an Correlation-ID for the incoming request,
// or extract the existing Correlation-ID from the incoming request. By default, any upstream Correlation-ID,
// passed in via the `X-Request-ID` header will be ignored. To enable this behaviour, the `WithPropagation`
// option should be passed into the options.
// Whether the Correlation-ID is generated or propagated, once inside this handler the request context
// will have a Correlation-ID associated with it.
func InjectCorrelationID(h http.Handler, opts ...InboundHandlerOption) http.Handler {
	config := applyInboundHandlerOptions(opts)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		parent := r.Context()

		correlationID := ""
		if config.propagation {
			correlationID = extractFromRequest(r)
		}

		if correlationID == "" {
			correlationID = generateRandomCorrelationIDWithFallback(r)
		}

		ctx := ContextWithCorrelation(parent, correlationID)
		h.ServeHTTP(w, r.WithContext(ctx))

		if config.sendResponseHeader {
			setResponseHeader(w, correlationID)
		}
	})
}

func extractFromRequest(r *http.Request) string {
	return r.Header.Get(propagationHeader)
}

// setResponseHeader will set the response header, if it has not already
// been set by an downstream response
func setResponseHeader(w http.ResponseWriter, correlationID string) {
	header := w.Header()
	_, exists := header[http.CanonicalHeaderKey(propagationHeader)]
	if !exists {
		header.Set(propagationHeader, correlationID)
	}
}

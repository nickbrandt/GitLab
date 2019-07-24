package raven

import (
	"context"

	raven "github.com/getsentry/raven-go"

	"gitlab.com/gitlab-org/labkit/correlation"
)

const ravenSentryExtraKey = "gitlab.CorrelationID"

// SetExtra will augment a raven message with the CorrelationID.
// An existing `extra` can be passed in, but if it's nil
// a new one will be created.
//
// Deprecated: Use gitlab.com/gitlab-org/labkit/errortracking instead.
func SetExtra(ctx context.Context, extra raven.Extra) raven.Extra {
	if extra == nil {
		extra = raven.Extra{}
	}

	correlationID := correlation.ExtractFromContext(ctx)
	if correlationID != "" {
		extra[ravenSentryExtraKey] = correlationID
	}

	return extra
}

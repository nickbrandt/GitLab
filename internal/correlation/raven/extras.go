package raven

import (
	"context"

	raven "github.com/getsentry/raven-go"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/correlation"
)

const ravenSentryExtraKey = "gitlab.CorrelationID"

// SetExtra will augment a raven message with the CorrelationID
// An existing `extra` can be passed in, but if it's nil
// a new one will be created
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

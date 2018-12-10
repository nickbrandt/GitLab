package log

import (
	"context"

	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/labkit/correlation"
)

// Fields type, an helper to avoid importing logrus.Fields
type Fields map[string]interface{}

func toLogrusFields(f Fields) logrus.Fields {
	lFields := logrus.Fields{}
	for k, v := range f {
		lFields[k] = v
	}

	return lFields
}

func getCorrelationID(ctx context.Context) string {
	correlationID := correlation.ExtractFromContext(ctx)
	if correlationID == "" {
		return "[MISSING]"
	}
	return correlationID
}

// WithContext provides a *logrus.Entry with the proper "correlation_id" field.
//
// "[MISSING]" will be used when ctx has no value for KeyCorrelationID
func WithContext(ctx context.Context) *logrus.Entry {
	return logrus.WithField("correlation_id", getCorrelationID(ctx))
}

// NoContext provides logrus.StandardLogger()
func NoContext() *logrus.Logger {
	return logrus.StandardLogger()
}

// WrapEntry adds the proper "correlation_id" field to the provided *logrus.Entry
func WrapEntry(ctx context.Context, e *logrus.Entry) *logrus.Entry {
	return e.WithField("correlation_id", getCorrelationID(ctx))
}

// WithFields decorates logrus.WithFields with the proper "correlation_id"
func WithFields(ctx context.Context, f Fields) *logrus.Entry {
	return WithContext(ctx).WithFields(toLogrusFields(f))
}

// WithField decorates logrus.WithField with the proper "correlation_id"
func WithField(ctx context.Context, key string, value interface{}) *logrus.Entry {
	return WithContext(ctx).WithField(key, value)
}

// WithError decorates logrus.WithError with the proper "correlation_id"
func WithError(ctx context.Context, err error) *logrus.Entry {
	return WithContext(ctx).WithError(err)
}

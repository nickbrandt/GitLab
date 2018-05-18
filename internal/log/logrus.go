package log

import (
	"context"

	"github.com/sirupsen/logrus"
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
	noID := "[MISSING]"
	if ctx == nil {
		return noID
	}

	id := ctx.Value(KeyCorrelationID)

	str, ok := id.(string)
	if !ok {
		return noID
	}

	return str
}

// WithContext provides a *logrus.Entry with the proper "correlation-id" field.
//
// "[MISSING]" will be used when ctx has no value for KeyCorrelationID
func WithContext(ctx context.Context) *logrus.Entry {
	return logrus.WithField("correlation-id", getCorrelationID(ctx))
}

// NoContext provides logrus.StandardLogger()
func NoContext() *logrus.Logger {
	return logrus.StandardLogger()
}

// WrapEntry adds the proper "correlation-id" field to the provided *logrus.Entry
func WrapEntry(ctx context.Context, e *logrus.Entry) *logrus.Entry {
	return e.WithField("correlation-id", getCorrelationID(ctx))
}

// WithFields decorates logrus.WithFields with the proper "correlation-id"
func WithFields(ctx context.Context, f Fields) *logrus.Entry {
	return WithContext(ctx).WithFields(toLogrusFields(f))
}

// WithField decorates logrus.WithField with the proper "correlation-id"
func WithField(ctx context.Context, key string, value interface{}) *logrus.Entry {
	return WithContext(ctx).WithField(key, value)
}

// WithError decorates logrus.WithError with the proper "correlation-id"
func WithError(ctx context.Context, err error) *logrus.Entry {
	return WithContext(ctx).WithError(err)
}

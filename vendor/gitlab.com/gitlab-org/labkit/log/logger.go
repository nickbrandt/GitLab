package log

import (
	"context"
	"os"

	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/correlation"
)

var logger = logrus.StandardLogger()

func init() {
	// Enfore our own defaults on the logrus stdlogger
	logger.Out = os.Stderr
	logger.Formatter = &logrus.TextFormatter{}
	logger.Level = logrus.InfoLevel
}

// ContextLogger will set the correlation id in the logger based on the context.
// This reference should not be held outside of the scope of the context
func ContextLogger(ctx context.Context) *logrus.Entry {
	return logger.WithFields(ContextFields(ctx))
}

// WithContextFields is a utility method for logging with context and fields
func WithContextFields(ctx context.Context, fields Fields) *logrus.Entry {
	return logger.WithFields(ContextFields(ctx)).WithFields(fields)
}

// ContextFields a logrus fields structure with the CorrelationID set
func ContextFields(ctx context.Context) Fields {
	correlationID := correlation.ExtractFromContext(ctx)

	return logrus.Fields{correlation.FieldName: correlationID}
}

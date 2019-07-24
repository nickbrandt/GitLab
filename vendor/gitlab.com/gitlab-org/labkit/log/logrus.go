package log

import (
	"github.com/sirupsen/logrus"
)

// Note that we specifically discourage the use of Fatal, Error by excluding them from the API.
// Since we prefer structured logging with `.WithError(err)`

// Fields is an alias for the underlying logger Fields type
// Using this alias saves clients from having to import
// two distinct logging packages, which can be confusing
type Fields = logrus.Fields

// New is a delegator method for logrus.New
func New() *logrus.Logger {
	return logrus.New()
}

// Info is a delegator method for logrus.Info
// Info is an exception to our rule about discouraging non-structured use, as there are valid
// reasons for simply emitting a single log line.
func Info(args ...interface{}) {
	logger.Info(args...)
}

// WithField is a delegator method for logrus.WithField
func WithField(key string, value interface{}) *logrus.Entry {
	return logger.WithField(key, value)
}

// WithFields is a delegator method for logrus.WithFields
func WithFields(fields Fields) *logrus.Entry {
	return logger.WithFields(fields)
}

// WithError is a delegator method for logrus.WithError
func WithError(err error) *logrus.Entry {
	return logger.WithError(err)
}

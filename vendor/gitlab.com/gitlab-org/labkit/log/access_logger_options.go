package log

import (
	"net/http"

	"github.com/sirupsen/logrus"
)

// ExtraFieldsGeneratorFunc allows extra fields to be included in the access log.
type ExtraFieldsGeneratorFunc func(r *http.Request) Fields

// The configuration for an access logger
type accessLoggerConfig struct {
	logger      *logrus.Logger
	extraFields ExtraFieldsGeneratorFunc
	fields      AccessLogField
}

func nullExtraFieldsGenerator(r *http.Request) Fields {
	return Fields{}
}

// AccessLoggerOption will configure a access logger handler.
type AccessLoggerOption func(*accessLoggerConfig)

func applyAccessLoggerOptions(opts []AccessLoggerOption) accessLoggerConfig {
	config := accessLoggerConfig{
		logger:      logger,
		extraFields: nullExtraFieldsGenerator,
		fields:      defaultEnabledFields,
	}
	for _, v := range opts {
		v(&config)
	}

	return config
}

// WithExtraFields allows extra fields to be passed into the access logger, based on the request.
func WithExtraFields(f ExtraFieldsGeneratorFunc) AccessLoggerOption {
	return func(config *accessLoggerConfig) {
		config.extraFields = f
	}
}

// WithFieldsExcluded allows fields to be excluded from the access log. For example, backend services may not require the referer or user agent fields.
func WithFieldsExcluded(fields AccessLogField) AccessLoggerOption {
	return func(config *accessLoggerConfig) {
		config.fields = config.fields &^ fields
	}
}

// WithAccessLogger configures the logger to be used with the access logger.
func WithAccessLogger(logger *logrus.Logger) AccessLoggerOption {
	return func(config *accessLoggerConfig) {
		config.logger = logger
	}
}

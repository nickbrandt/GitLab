package tracing

import (
	"io"

	opentracing "github.com/opentracing/opentracing-go"
	log "github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/tracing/connstr"
	"gitlab.com/gitlab-org/labkit/tracing/impl"
)

type nopCloser struct {
}

func (nopCloser) Close() error { return nil }

// Initialize will initialize distributed tracing
func Initialize(opts ...InitializationOption) io.Closer {
	config := applyInitializationOptions(opts)

	if config.connectionString == "" {
		// No opentracing connection has been set
		return &nopCloser{}
	}

	driverName, options, err := connstr.Parse(config.connectionString)
	if err != nil {
		log.WithError(err).Infoln("unable to parse connection")
		return &nopCloser{}
	}

	if config.serviceName != "" {
		options["ServiceName"] = config.serviceName
	}

	tracer, closer, err := impl.New(driverName, options)
	if err != nil {
		log.WithError(err).Warn("skipping tracing configuration step")
		return &nopCloser{}
	}

	if tracer == nil {
		log.Warn("no tracer provided, tracing will be disabled")
	} else {
		log.Info("Tracing enabled")
		opentracing.SetGlobalTracer(tracer)
	}

	if closer == nil {
		return &nopCloser{}
	}
	return closer
}

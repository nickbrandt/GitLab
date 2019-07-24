package main

import (
	"fmt"
	"io"
	"io/ioutil"
	goLog "log"
	"os"

	log "github.com/sirupsen/logrus"
	logkit "gitlab.com/gitlab-org/labkit/log"
)

const (
	jsonLogFormat    = "json"
	textLogFormat    = "text"
	structuredFormat = "structured"
	noneLogType      = "none"
)

type logConfiguration struct {
	logFile   string
	logFormat string
}

func startLogging(config logConfiguration) (io.Closer, error) {
	// Golog always goes to stderr
	goLog.SetOutput(os.Stderr)

	logFile := config.logFile
	if logFile == "" {
		logFile = "stderr"
	}

	switch config.logFormat {
	case noneLogType:
		return logkit.Initialize(logkit.WithWriter(ioutil.Discard))
	case jsonLogFormat:
		return logkit.Initialize(
			logkit.WithOutputName(logFile),
			logkit.WithFormatter("json"),
		)
	case textLogFormat:
		// In this mode, default (non-access) logs will always go to stderr
		return logkit.Initialize(
			logkit.WithOutputName("stderr"),
			logkit.WithFormatter("text"),
		)
	case structuredFormat:
		return logkit.Initialize(
			logkit.WithOutputName(logFile),
			logkit.WithFormatter("color"),
		)
	}

	return nil, fmt.Errorf("unknown logFormat: %v", config.logFormat)
}

// In text format, we use a separate logger for access logs
func getAccessLogger(config logConfiguration) (*log.Logger, io.Closer, error) {
	if config.logFormat != "text" {
		return log.StandardLogger(), nil, nil
	}

	logFile := config.logFile
	if logFile == "" {
		logFile = "stderr"
	}

	accessLogger := log.New()
	accessLogger.SetLevel(log.InfoLevel)
	closer, err := logkit.Initialize(
		logkit.WithLogger(accessLogger),  // Configure `accessLogger`
		logkit.WithFormatter("combined"), // Use the combined formatter
		logkit.WithOutputName(logFile),
	)

	return accessLogger, closer, err
}

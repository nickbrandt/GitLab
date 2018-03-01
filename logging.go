package main

import (
	"io"
	"io/ioutil"
	goLog "log"
	"os"
	"os/signal"
	"syscall"

	"github.com/client9/reopen"
	log "github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func reopenLogWriter(l reopen.WriteCloser, sighup chan os.Signal) {
	for _ = range sighup {
		log.Print("Reopening log file")
		l.Reopen()
	}
}

func prepareLoggingFile(logFile string) *reopen.FileWriter {
	file, err := reopen.NewFileWriter(logFile)
	if err != nil {
		goLog.Fatalf("Unable to set output log: %s", err)
	}

	sighup := make(chan os.Signal, 1)
	signal.Notify(sighup, syscall.SIGHUP)

	go reopenLogWriter(file, sighup)
	return file
}

const (
	jsonLogFormat = "json"
	textLogFormat = "text"
	noneLogType   = "none"
)

type logConfiguration struct {
	logFile   string
	logFormat string
}

func startLogging(config logConfiguration) {
	var accessLogEntry *log.Entry
	var logOutputWriter io.Writer

	if config.logFile != "" {
		logOutputWriter = prepareLoggingFile(config.logFile)
	} else {
		logOutputWriter = os.Stderr
	}

	switch config.logFormat {
	case noneLogType:
		accessLogEntry = nil
		logOutputWriter = ioutil.Discard
	case jsonLogFormat:
		accessLogEntry = log.WithField("system", "http")
		log.SetFormatter(&log.JSONFormatter{})
	case textLogFormat:
		accessLogger := log.New()
		accessLogger.Formatter = helper.NewAccessLogFormatter()
		accessLogger.Out = logOutputWriter
		accessLogger.SetLevel(log.InfoLevel)
		accessLogEntry = accessLogger.WithField("system", "http")

		log.SetFormatter(&log.TextFormatter{})
	default:
		log.WithField("logFormat", config.logFormat).Fatal("Unknown logFormat configured")
	}

	helper.SetAccessLoggerEntry(accessLogEntry)
	log.SetOutput(logOutputWriter)

	// Golog always goes to stderr
	goLog.SetOutput(os.Stderr)

}

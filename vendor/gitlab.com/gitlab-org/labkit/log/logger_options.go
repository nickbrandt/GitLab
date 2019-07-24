package log

import (
	"fmt"
	"io"
	"os"

	"github.com/sirupsen/logrus"
)

type loggerConfig struct {
	logger     *logrus.Logger
	level      logrus.Level
	formatter  logrus.Formatter
	outputPath string
	writer     io.Writer

	// A list of warnings that will be emitted once the logger is configured
	warnings []string
}

// LoggerOption will configure a new logrus Logger
type LoggerOption func(*loggerConfig)

func applyLoggerOptions(opts []LoggerOption) *loggerConfig {
	conf := loggerConfig{
		logger:    logger,
		level:     logrus.InfoLevel,
		formatter: &logrus.TextFormatter{},
		writer:    os.Stdout,
	}

	for _, v := range opts {
		v(&conf)
	}

	return &conf
}

// WithFormatter allows setting the format to `text`, `json`, `color` or `combined`. In case
// the input is not recognized it defaults to text with a warning.
// More details of these formats:
// * `text` - human readable.
// * `json` - computer readable, new-line delimited JSON.
// * `color` - human readable, in color. Useful for development.
// * `combined` - httpd access logs. Good for legacy access log parsers.
func WithFormatter(format string) LoggerOption {
	return func(conf *loggerConfig) {
		switch format {
		case "text":
			conf.formatter = &logrus.TextFormatter{}
		case "color":
			conf.formatter = &logrus.TextFormatter{ForceColors: true, EnvironmentOverrideColors: true}
		case "json":
			conf.formatter = &logrus.JSONFormatter{}
		case "combined":
			conf.formatter = newCombinedcombinedAccessLogFormatter()
		default:
			conf.warnings = append(conf.warnings, fmt.Sprintf("unknown logging format %s, ignoring option", format))
		}
	}
}

// WithLogLevel is used to set the log level when defaulting to `info` is not
// wanted. Other options are: `debug`, `warn`, `error`, `fatal`, and `panic`.
func WithLogLevel(level string) LoggerOption {
	return func(conf *loggerConfig) {
		logrusLevel, err := logrus.ParseLevel(level)
		if err != nil {
			conf.warnings = append(conf.warnings, fmt.Sprintf("unknown log level, ignoring option: %v", err))
		} else {
			conf.level = logrusLevel
		}
	}
}

// WithOutputName allows customization of the sink of the logger. Output is either:
// `stdout`, `stderr`, or a path to a file.
func WithOutputName(outputName string) LoggerOption {
	return func(conf *loggerConfig) {
		switch outputName {
		case "stdout":
			conf.writer = os.Stdout
		case "stderr":
			conf.writer = os.Stderr
		default:
			conf.writer = nil
			conf.outputPath = outputName
		}
	}
}

// WithWriter allows the writer to be customized. The application is responsible for closing the writer manually.
func WithWriter(writer io.Writer) LoggerOption {
	return func(conf *loggerConfig) {
		conf.writer = writer
	}
}

// WithLogger allows you to configure a proprietary logger using the `Initialize` method
func WithLogger(logger *logrus.Logger) LoggerOption {
	return func(conf *loggerConfig) {
		conf.logger = logger
	}
}

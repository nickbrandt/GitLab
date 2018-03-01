package helper

import (
	"io/ioutil"
	"testing"
	"time"

	log "github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
)

func TestAccessLogFormatter_Format(t *testing.T) {
	discardLogger := log.New()
	discardLogger.Out = ioutil.Discard

	tests := []struct {
		name  string
		entry *log.Entry
		want  string
	}{
		{
			"blank",
			discardLogger.WithField("blank", ""),
			"-  - - [2018/01/07:00:00:00 +0000] \"  \" 0 0 \"\" \"\" 0.000\n",
		},
		{
			"full",
			discardLogger.WithFields(log.Fields{
				"host":       "gitlab.com",
				"remoteAddr": "127.0.0.1",
				"method":     "GET",
				"uri":        "/",
				"proto":      "HTTP/1.1",
				"status":     200,
				"written":    100,
				"referer":    "http://localhost",
				"userAgent":  "Mozilla/1.0",
				"duration":   5.0,
			}),
			"gitlab.com 127.0.0.1 - - [2018/01/07:00:00:00 +0000] \"GET / HTTP/1.1\" 200 100 \"http://localhost\" \"Mozilla/1.0\" 5.000\n",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			f := &accessLogFormatter{clock: &StubClock{time.Unix(1515283200, 0)}}

			got, err := f.Format(tt.entry)
			if err != nil {
				t.Errorf("AccessLogFormatter.Format() error = %v", err)
				return
			}

			assert.Equal(t, tt.want, string(got))
		})
	}
}

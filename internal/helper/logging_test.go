package helper

import (
	"fmt"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func Test_statsCollectingResponseWriter_accessLogFields(t *testing.T) {
	passwords := []string{
		"should_be_filtered",        // Basic case
		"should+++filtered",         // Password contains  +
		"this/is/a/to--ken",         // Password contains on / and -
		"%E9%A9%AE%E9%A9%AC",        // Password contains URI Encoded chars
		"should_be_%252E%252E%252F", // Password is mixed
	}

	queryStrings := []string{
		"private-token=%s",
		"authenticity-token=%s",
		"rss-token=%s",
		"private_token=%s",
		"authenticity_token=%s",
		"rss-token=%s",
		"private-token=%s&authenticity-token=%s",
		"private_token=%s&authenticity_token=%s",
		"param=not_private&private-token=%s", // Non-private fields prefixed
		"private-token=%s&param=not_private", // Non-private fields suffixed
	}

	paths := []string{
		"",
		"/",
		"/groups/private_token/",
	}

	for i, password := range passwords {
		for j, path := range paths {
			for k, qs := range queryStrings {
				queryString := strings.Replace(qs, "%s", password, -1)
				t.Run(fmt.Sprintf("Test #%v %v %v", i, j, k), func(t *testing.T) {
					resource := path + "?" + queryString

					// Ensure the Referer is scrubbed too
					req, err := http.NewRequest("GET", "/blah"+resource, nil)
					assert.NoError(t, err, "GET %q: %v", resource, err)

					req.Header.Set("Referer", "http://referer.example.com"+resource)
					req.RequestURI = resource

					l := &statsCollectingResponseWriter{
						rw:          nil,
						status:      200,
						wroteHeader: true,
						written:     50,
						started:     time.Now(),
					}

					fields := l.accessLogFields(req)

					uri := fields["uri"].(string)
					assert.NotEmpty(t, uri, "uri is empty")
					assert.Contains(t, uri, path, "GET %q: path not logged", resource)
					assert.NotContains(t, uri, password, "GET %q: log not filtered correctly", resource)

					referer := fields["referer"].(string)
					assert.NotEmpty(t, referer, "referer is empty")
					assert.Contains(t, referer, path, "GET %q: path not logged", resource)
					assert.NotContains(t, referer, password, "GET %q: log not filtered correctly", resource)

					assert.NotContains(t, fmt.Sprintf("%#v", fields), password, "password leaked into fields", fields)

					if strings.Contains(queryString, "param=not_private") {
						assert.Contains(t, uri, "param=not_private", "Missing non-private parameters in uri", uri)
						assert.Contains(t, referer, "param=not_private", "Missing non-private parameters in referer", referer)
					}
				})

			}
		}
	}

}

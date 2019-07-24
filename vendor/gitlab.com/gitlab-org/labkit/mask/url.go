package mask

import (
	"bytes"
	"net/url"
)

// URL will mask the sensitive components in an URL with `[FILTERED]`.
// This list should maintain parity with the list in
// GitLab-CE, maintained at https://gitlab.com/gitlab-org/gitlab-ce/blob/master/config/application.rb.
// Based on https://stackoverflow.com/a/52965552/474597.
func URL(originalURL string) string {
	u, err := url.Parse(originalURL)
	if err != nil {
		return "<invalid URL>"
	}

	redactionBytes := []byte(RedactionString)
	buf := bytes.NewBuffer(make([]byte, 0, len(originalURL)))

	for i, queryPart := range bytes.Split([]byte(u.RawQuery), []byte("&")) {
		if i != 0 {
			buf.WriteByte('&')
		}

		splitParam := bytes.SplitN(queryPart, []byte("="), 2)

		if len(splitParam) == 2 {
			buf.Write(splitParam[0])
			buf.WriteByte('=')

			if parameterMatcher.Match(splitParam[0]) {
				buf.Write(redactionBytes)
			} else {
				buf.Write(splitParam[1])
			}
		} else {
			buf.Write(queryPart)
		}
	}
	u.RawQuery = buf.String()
	return u.String()
}

package webpack

import (
	"fmt"
	"net/http"
	"net/http/httputil"
	"net/url"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
)

func DevServer(enabled bool, address string, fallbackHandler http.Handler) http.Handler {
	if !enabled {
		return fallbackHandler
	}

	u, err := buildURL(address)
	if err != nil {
		panic(err)
	}

	return httputil.NewSingleHostReverseProxy(u)
}

func buildURL(address string) (*url.URL, error) {
	u := helper.URLMustParse(address)
	if u == nil {
		return nil, fmt.Errorf("failed to parse URL in %q", address)
	}

	// Hope to support unix:// in the future
	if u.Scheme != "tcp" {
		return nil, fmt.Errorf("invalid scheme: %v", u)
	}

	u.Scheme = "http"
	return u, nil
}

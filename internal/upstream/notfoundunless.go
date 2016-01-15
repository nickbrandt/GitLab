package upstream

import "net/http"

func NotFoundUnless(pass bool, handler http.Handler) http.Handler {
	if pass {
		return handler
	} else {
		return http.HandlerFunc(http.NotFound)
	}
}

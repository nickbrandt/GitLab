package upstream

import "net/http"

func handleDevelopmentMode(developmentMode bool, handler http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !developmentMode {
			http.NotFound(w, r)
			return
		}

		handler(w, r)
	}
}

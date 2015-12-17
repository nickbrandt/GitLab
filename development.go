package main

import "net/http"

func handleDevelopmentMode(developmentMode *bool, handler handleFunc) handleFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if !*developmentMode {
			http.NotFound(w, r)
			return
		}

		handler(w, r)
	}
}

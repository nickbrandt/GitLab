package main

import "net/http"

func handleDevelopmentMode(developmentMode *bool, handler serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		if !*developmentMode {
			http.NotFound(w, r.Request)
			return
		}

		handler(w, r)
	}
}

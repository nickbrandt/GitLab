package main

import (
	"io/ioutil"
	"net/http"
)

func handleDeployPage(deployPage *string, handler serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		data, err := ioutil.ReadFile(*deployPage)
		if err != nil {
			handler(w, r)
			return
		}

		setNoCacheHeaders(w.Header())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	}
}

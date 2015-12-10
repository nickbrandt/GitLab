package main

import (
	"io/ioutil"
	"net/http"
	"path/filepath"
)

func handleDeployPage(documentRoot *string, handler serviceHandleFunc) serviceHandleFunc {
	return func(w http.ResponseWriter, r *gitRequest) {
		deployPage := filepath.Join(*documentRoot, "index.html")
		data, err := ioutil.ReadFile(deployPage)
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

package main

import (
	"./internal/helper"
	"io/ioutil"
	"net/http"
	"path/filepath"
)

func handleDeployPage(documentRoot string, handler http.Handler) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		deployPage := filepath.Join(documentRoot, "index.html")
		data, err := ioutil.ReadFile(deployPage)
		if err != nil {
			handler.ServeHTTP(w, r)
			return
		}

		helper.SetNoCacheHeaders(w.Header())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	}
}

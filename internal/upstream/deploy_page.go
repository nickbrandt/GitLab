package upstream

import (
	"../helper"
	"io/ioutil"
	"net/http"
	"path/filepath"
)

func handleDeployPage(documentRoot string, handler http.Handler) http.HandlerFunc {
	deployPage := filepath.Join(documentRoot, "index.html")

	return func(w http.ResponseWriter, r *http.Request) {
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
